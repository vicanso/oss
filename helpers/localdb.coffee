fs = require 'fs'
path = require 'path'
async = require 'async'
_ = require 'underscore'
config = require '../config'
fileName = path.join config.getAppPath(), 'user.json'
getUserSettings = ->
  if fs.existsSync fileName
    data = fs.readFileSync fileName
    if data
      data = JSON.parse data
  else
    {}
saveUserSettings = ->
  fs.writeFileSync fileName, JSON.stringify UserSettings
UserSettings = getUserSettings()


localDb =
  findOne : (hash) ->
    UserSettings[hash]
  save : (hash, data) ->
    UserSettings[hash] = data
    saveUserSettings()
  update : (hash, data) ->
    _.extend UserSettings[hash], data
    saveUserSettings()


module.exports = localDb