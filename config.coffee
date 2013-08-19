setting = require './app_setting'
path = require 'path'
fs = require 'fs'
# process.env.NODE_ENV = 'nodewebkit'
isProductionMode = process.env.NODE_ENV == 'production'
isNodeWebKitMode = process.env.NODE_ENV == 'nodewebkit'

host = 'localhost'
staticMaxAge = 1
convertExts = null
if isProductionMode
  staticMaxAge = 48 * 3600 * 1000
  staticVersion = fs.readFileSync path.join __dirname, '/version'
  staticHosts = ['http://soss.vicanso.com']
  host = ['oss.vicanso.com', 'soss.vicanso.com']
  convertExts = 
    src : ['.coffee', '.styl']
    dst : ['.js', '.css']
sessionParser = null


if isNodeWebKitMode
  convertExts = 
    src : ['.coffee', '.styl']
    dst : ['.js', '.css']
  userSession = {}
  sessionParser = (req, res, cbf) ->
    req.session = userSession
    cbf null
else
  mongodb = setting.mongodb
  dbName = mongodb.dbName
  uri = mongodb.uri
  options =
    db : 
      native_parser : false
    server :
      poolSize : 5
  jtMongoose = require 'jtmongoose'
  jtMongoose.init dbName, uri, options

  jtMongoose.model dbName, 'user', {
    hash : String
    globalSetting : [{}]
    headerSetting : [{}]
  }

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
    convertExts : convertExts
    mergeList : [
      ['/javascripts/jquery/jquery-2.0.3.js'
      '/javascripts/utils/underscore.js'
      '/javascripts/utils/backbone.js'
      '/javascripts/utils/async.js'
      '/javascripts/jquery/jquery.cookie.js']
    ]
  route : ->
    require './routes'
if !isNodeWebKitMode
  jtRedis = require 'jtredis'
  jtRedis.configure
    redis : setting.redis
  config.session = ->
    key : 'vicanso_oss'
    secret : 'jenny&tree'
    ttl : 120 * 60
    client : jtRedis.getClient 'vicanso'
    complete : (parser) ->
      sessionParser = parser
module.exports = config