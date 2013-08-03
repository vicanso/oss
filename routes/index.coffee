config = require '../config'
appPath = config.getAppPath()
async = require 'async'
JTOss = require 'jtoss'
pageContentHandler = require "#{appPath}/helpers/pagecontenthandler"
sessionParser = config.sessionParser()
infoParser = (req, res, next) ->
  async.series [
    (cbf) ->
      sessionParser req, res, cbf
    (cbf) ->
      sess = req.session
      ossInfo = sess?.ossInfo
      if ossInfo?.keyId && ossInfo.keySecret
        ossClient = new JTOss ossInfo.keyId, ossInfo.keySecret
        if sess.userMetas
          # console.dir sess.userMetas
          ossClient.userMetas sess.userMetas
        req.ossClient = ossClient
        next()
      else
        err = new Error 'is not login!'
        err.status = 401
        next err
  ]
  # sessionParser req, res, () ->



routeInfos = [
  {
    route : '/'
    template : 'index'
    handler : pageContentHandler.index
  }
  {
    route : '/deletebucket/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.deleteBucket
  }
  {
    route : '/buckets'
    middleware : [infoParser]
    handler : pageContentHandler.buckets
  }
  {
    route : '/headobject/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.headObject
  }
  {
    type : 'post'
    route : '/headobject/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.headObject
  }
  {
    type : 'post'
    route : '/headobjects/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.headObjects
  }
  {
    route : '/objects/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.objects
  }
  # {
  #   type : 'all'
  #   route : '/oss/bucket/:bucket'
  #   handler : pageContentHandler.bucket
  # }
  {
    type : 'post'
    route : '/deleteobjects/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.deleteObjects
  }
  {
    type : 'delete'
    route : '/deleteobject/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.deleteObject
  }
  {
    route : ['/createbucket/:bucket', '/createbucket/:bucket/:competence']
    middleware : [infoParser]
    handler : pageContentHandler.createBucket
  }
  {
    type : 'all'
    route : '/upload'
    middleware : [infoParser]
    handler : pageContentHandler.upload
  }
  {
    type : 'post'
    route : '/login'
    middleware : [sessionParser]
    handler : pageContentHandler.login
  }
  {
    type : ['post', 'get']
    route : '/setting'
    middleware : [sessionParser]
    handler : pageContentHandler.setting
  }
  {
    route : '/createfolder/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.createFolder
  }
  {
    route : '/search/:bucket'
    middleware : [infoParser]
    handler : pageContentHandler.search
  }
  # {
  #   type : 'post'
  #   route : '/updateobjectheader/:bucket'
  #   handler : pageContentHandler.updateObjectHeader
  # }
]
module.exports = routeInfos