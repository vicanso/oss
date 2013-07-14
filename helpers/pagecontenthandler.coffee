_ = require 'underscore'
async = require 'async'
fs = require 'fs'
crypto = require 'crypto'
JTOss = require 'jtoss'
ossDBClient = require('jtmongodb').getClient 'oss'
wrapperCbf = (cbf) ->
  _.wrap cbf, (func, err, data) ->
    func err, data, {
      'Cache-Control' : 'no-cache, no-store'
    }

pageContentHandler =
  index : (req, res, cbf) ->
    cbf null, {
      title : '测试'
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
    ossClient.listBuckets (err, buckets) ->
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
      ossClient.updateObjectHeader bucket, obj, headers, cbf
    else
      ossClient.headObject bucket, obj, (err, res) ->
        if err
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
      ossClient.updateObjectHeader bucket, obj, headers, cbf
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
      ossClient.listObjects bucket, {prefix : prefix, delimiter : delimiter, marker : marker, 'max-keys' : maxKeys}, cbf
    else
      prefix = ''
      query =
        prefix : prefix
        keyword : keyword
        searchType : searchType
        marker : marker
        'max-keys' : maxKeys
        max : maxKeys
        delimiter : delimiter
      ossClient.listObjectsByCustom bucket, query, cbf
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
      _.each objs, (obj) ->
        len = obj.length
        if obj.charAt(len - 1) == '/'
          obj = obj.substring 0, len - 1
    #   xmlArr = ['<?xml version="1.0" encoding="UTF-8"?><Delete><Quiet>true</Quiet>']
    #   _.each objs, (obj) ->
    #     len = obj.length
    #     if obj.charAt(len - 1) == '/'
    #       obj = obj.substring 0, len - 1
    #     xmlArr.push "<Object><Key>#{obj}</Key></Object>"
    #   xmlArr.push '</Delete>'
      ossClient.deleteObjects bucket, objs, cbf
    else
      cbf null
  createBucket : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    ossClient = req.ossClient
    bucket = req.param 'bucket'
    if bucket
      ossClient.createBucket bucket, cbf
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
    ossClient.putObject data.bucket, "#{data.path || ''}#{data.Filename}", filePath, (err, data) ->
      fs.unlink filePath
      cbf err, data
  login : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    sess = req.session
    ossInfo = req.body
    ossInfo.userHash = crypto.createHash('sha1').update("#{ossInfo.keyId}#{ossInfo.keySecret}").digest 'hex'
    async.waterfall [
      (cbf) ->
        ossClient = new JTOss ossInfo.keyId, ossInfo.keySecret
        ossClient.listBuckets cbf
      (buckets, cbf) ->
        ossDBClient.findOne 'user', {hash : ossInfo.userHash}, cbf
      (data, cbf) ->
        if data
          # _.extend ossInfo, data
          cbf null, data
        else
          ossDBClient.save 'user', {hash : ossInfo.userHash}, cbf
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
        setting = sess.globalSetting || [
          {
            key : 'eachPageSize'
            desc : '每页显示数量(1-1000)'
            value : 100
          }
        ]
      else
        setting = sess.headerSetting || []
      cbf null, setting
    else
      if type == 'global'
        sess.globalSetting = req.body.setting
        ossDBClient.update 'user', {hash : sess.ossInfo.userHash}, {'$set' : {globalSetting : req.body.setting}},  ->
      else
        sess.headerSetting = req.body.setting
        ossDBClient.update 'user', {hash : sess.ossInfo.userHash}, {'$set' : {headerSetting : req.body.setting}},  ->
        sess.userMetas = converUserMetas req.body.setting
      cbf null
  createFolder : (req, res, cbf) ->
    cbf = wrapperCbf cbf
    bucket = req.param 'bucket'
    folderPath = req.param('path') + '/'
    ossClient = req.ossClient
    ossClient.putObject bucket, folderPath, null, cbf
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
module.exports = pageContentHandler