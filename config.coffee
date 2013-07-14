setting = require './setting'
jtRedis = require 'jtredis'
path = require 'path'
jtRedis.configure
  query : true
  redis : setting.redis

jtMongodb = require 'jtmongodb'
jtMongodb.set {
  queryTime : true
  valiate : true
  timeOut : 0
  mongodb : setting.mongodb
}
isProductionMode = process.env.NODE_ENV == 'production'

host = 'localhost'
staticMaxAge = 1
if isProductionMode
  staticMaxAge = 48 * 3600 * 1000
  staticVersion = fs.readFileSync path.join __dirname, '/version'
  staticHosts = ['http://soss.vicanso.com']
  host = ['oss.vicanso.com', 'soss.vicanso.com']

sessionParser = null

config = 
  getAppPath : ->
    __dirname
  sessionParser : ->
    sessionParser

    
  host : host
  express : 
    set : 
      'view engine' : 'jade'
      views : "#{__dirname}/views"
  static : 
    path : "#{__dirname}/statics"
    urlPrefix : '/static'
    mergePath : "#{__dirname}/statics/temp"
    mergeUrlPrefix : '/temp'
    maxAge : staticMaxAge
    version : staticVersion
    hosts : staticHosts
    mergeList : [
      ['/common/javascripts/utils/underscore.min.js', '/common/javascripts/utils/async.min.js']
    ]
  route : ->
    require './routes'
  session : ->
    key : 'vicanso_oss'
    secret : 'jenny&tree'
    ttl : 120 * 60
    client : jtRedis.getClient 'vicanso'
    complete : (parser) ->
      sessionParser = parser
module.exports = config