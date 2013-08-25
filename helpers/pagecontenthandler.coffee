_ = require 'underscore'
async = require 'async'
fs = require 'fs'
glob = require 'glob'
crypto = require 'crypto'
JTOss = require 'jtoss'
isNodeWebKitMode = process.env.NODE_ENV == 'nodewebkit'
if !isNodeWebKitMode
  jtMongoose = require 'jtmongoose'
  User = jtMongoose.model 'oss', 'user'
else
  localDb = require './localdb'

wrapperCbf = (cbf) ->
  _.wrap cbf, (func, err, data) ->
    func err, data, {
      'Cache-Control' : 'no-cache, no-store'
    }

pageContentHandler =
  index : (req, res, cbf) ->
    cbf null, {
      title : 'OSS管理后台'
    }
  deleteBucket : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    if bucket
      ossClient.deleteBucket bucket, cbf
    else
      cbf new Error 'the bucket can not be null!'
  buckets : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    ossClient.getService (err, buckets) ->
      if err
        cbf err
      else
        cbf null, buckets 
  headObject : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    obj = req.param 'obj'
    if req.method == 'POST'
      headers = _.pick req.body, 'Content-Language Expires Cache-Control Content-Encoding Content-Disposition'.split ' '
      ossClient.headObject bucket, obj, headers, cbf
    else
      ossClient.headObject bucket, obj, (err, res) ->
        if err
          console.dir err
          cbf err
        else
          cbf null, res
  headObjects : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    headers = req.body.headers || {}
    objs = req.body.objs
    async.eachLimit objs, 10, (obj, cbf) ->
      ossClient.headObject bucket, obj, headers, cbf
    , cbf
  objects : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    prefix = req.param('prefix') || ''
    searchType = req.param 'searchType'
    keyword = req.param 'keyword'
    marker = req.param 'marker'
    delimiter = req.param 'delimiter' 
    globalSetting = req.session?.globalSetting
    maxKeys = 100
    if globalSetting
      eachPageSize = _.find globalSetting, (setting) ->
        setting.key == 'eachPageSize'
      if eachPageSize
        maxKeys = eachPageSize.value
    if !searchType || searchType == 'prefix'
      prefix = prefix || keyword
      ossClient.listBucket bucket, {prefix : prefix, delimiter : delimiter, marker : marker, 'max-keys' : maxKeys}, cbf
    else
      prefix = ''
      filter = getFilter searchType, keyword
      params =
        prefix : prefix
        filter : filter
        marker : marker
        'max-keys' : maxKeys
        max : maxKeys
        delimiter : delimiter

      ossClient.listObjectsByFilter bucket, params, cbf
  deleteObject : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    obj = req.param 'obj'
    ossClient.deleteObject bucket, obj, cbf
  deleteObjects : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    data = req.body
    objs = data.objs
    if bucket && objs?.length
      ossClient.deleteObjects bucket, objs, cbf
    else
      cbf null
  createBucket : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    competence = req.param 'competence'
    if bucket
      ossClient.createBucket bucket, competence, cbf
    else
      err = new Error 'the bucket can not null!'
      err.msg = 'bucket的名字不能为空！'
      cbf err
  upload : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    data = req.body
    filePath = req.files.Filedata.path
    console.dir filePath
    console.dir data 
    ossClient.putObjectFromFile data.bucket, "#{data.path || ''}#{data.Filename}", filePath, (err, data) ->
      fs.unlink filePath
      cbf err, data
  uploadPath : (req, res, cbf) ->
    uploadPath = req.param 'uploadPath'
    console.dir uploadPath
    glob "#{uploadPath}/**", (err, files) ->
      cbf err, files
  putFiles : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    targetPath = req.param 'path'
    files = req.param('files').split ';'
    # console.dir files
    files = _.map files, (file) ->
      targetPath + file
    if VICANSO?.putFilesProgress
      progress = VICANSO.putFilesProgress
    else
      progress = ->
    params =
      progress : progress
    ossClient.putObjectFromFileList bucket, files, null, params, cbf
  login : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    sess = req.session
    ossInfo = req.body
    ossInfo.userHash = crypto.createHash('sha1').update("#{ossInfo.keyId}#{ossInfo.keySecret}").digest 'hex'
    async.waterfall [
      (cbf) ->
        ossClient = new JTOss ossInfo.keyId, ossInfo.keySecret
        ossClient.getService cbf
      (buckets, cbf) ->
        if User
          User.findOne 'user', {hash : ossInfo.userHash}, cbf
        else
          # TODO
          cbf null, localDb.findOne ossInfo.userHash
      (data, cbf) ->
        if data
          # _.extend ossInfo, data
          cbf null, data
        else
          if User
            new User({
              hash : ossInfo.userHash
            }).save cbf
          else
            localDb.save ossInfo.userHash, {}
            cbf null, null
    ], (err, data) ->
      if err
        cbf err
      else
        if data
          sess.globalSetting = data.globalSetting
          sess.headerSetting = data.headerSetting
          sess.userMetas = converUserMetas data.headerSetting
        sess.ossInfo = ossInfo
        cbf null
  setting : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    sess = req.session
    type = req.param('type') || 'global'
    if req.method == 'GET'
      if type == 'global'
        defaults = [
          {
            key : 'eachPageSize'
            desc : '每页显示数量(1-1000)'
            value : 100
          }
        ]
        setting = sess.globalSetting
        if !setting || !setting.length
          setting = defaults
      else
        setting = sess.headerSetting || []
      cbf null, setting
    else
      if type == 'global'
        sess.globalSetting = req.body.setting
        if User
          User.findOneAndUpdate {hash : sess.ossInfo.userHash}, {'$set' : {globalSetting : req.body.setting}},  ->
        else
          localDb.update sess.ossInfo.userHash, {globalSetting : req.body.setting}
      else
        sess.headerSetting = req.body.setting
        if User
          User.findOneAndUpdate {hash : sess.ossInfo.userHash}, {'$set' : {headerSetting : req.body.setting}},  ->
        else
          localDb.update sess.ossInfo.userHash, {headerSetting : req.body.setting}
        sess.userMetas = converUserMetas req.body.setting
      cbf null
  createFolder : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    bucket = req.param 'bucket'
    folderPath = req.param('path') + '/'
    ossClient = req.ossClient
    ossClient.putObjectWithData bucket, folderPath, null, cbf
  search : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    bucket = req.param 'bucket'
    keyword = req.param('keyword').trim()
    ossClient = req.ossClient
    ossClient.listObjects bucket, {prefix : keyword, 'max-keys' : 100}, cbf

converUserMetas = (headerSetting) ->
  userMetas = {}
  _.each headerSetting, (setting) ->
    typeList = setting.type.split ','
    _.each typeList, (type) ->
      type = type.trim()
      if type.charAt(0) != '.'
        type = ".#{type}"
      cfg = userMetas[type] ?= {}
      cfg[setting.header] = setting.value
  userMetas

getFilter = (searchType, keyword) ->
  if !searchType || !keyword
    return null
  if searchType == 'keyword'
    (objInfo) ->
      ~objInfo.name.indexOf keyword
  else
    le = true
    if keyword[0] == '>'
      le = false
      keyword = keyword.substring 1
    else if keyword[0] == '<'
      keyword = keyword.substring 1

    if searchType == 'modified'
      modified = new Date keyword
      (objInfo) ->
        lastModified = new Date objInfo.lastModified
        if le
          lastModified < modified
        else
          lastModified >= modified
    else if searchType == 'size'
      lastChar = keyword[keyword.length - 1]
      size = GLOBAL.parseFloat keyword
      if lastChar == 'K' || lastChar == 'k'
        size *= KB_SIZE
      else if lastChar == 'M' || lastChar == 'm'
        size *= MB_SIZE
      else if lastChar == 'G' || lastChar == 'g'
        size *= GB_SIZE
      (objInfo) ->
        if le
          objInfo.size < size
        else
          objInfo.size >= size
    else
      null

module.exports = pageContentHandler