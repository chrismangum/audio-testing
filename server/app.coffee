express = require 'express'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
app = express()
async = require 'async'
exec = require('child_process').exec
server = require('http').createServer app
io = require('socket.io').listen server

target = null
json = null

server.listen 3000
process.chdir __dirname

app.use express.logger 'dev'
app.set 'json spaces', 0
app.use '/static', express.static path.join __dirname, '../public'
app.get '/', (req, res) ->
  res.sendfile path.join __dirname, '../public/index.html'

class Scanner
  constructor: (@filePath) ->

  ftypes:
    '40': 'directory'
    '12': 'symlink'
    '10': 'file'

  validExtensions: [
    '.m4a'
    '.flac'
    '.mp3'
  ]

  getFtype: (mode) ->
    @ftypes[mode.toString(8).slice 0, 2]

  hasValidExt: (fileName) ->
    @validExtensions.indexOf(path.extname fileName) isnt -1

  getTotalSize: (tracks) ->
    totalSize = 0
    _.each tracks, (track) ->
      totalSize += track.fileSize;
    totalSize

  scan: (filePath = @filePath) ->
    items = {}
    _.each fs.readdirSync(filePath), (item) =>
      stat = fs.statSync filePath + item
      stat.type = @getFtype stat.mode
      if stat.type is 'directory'
        items = _.extend items, @scan filePath + item + '/'
      else if @hasValidExt item
        items[filePath + item] =
          fileName: item
          fileSize: stat.size
    items

class Json
  constructor: (@target, @socket) ->
    @check()

  emit: ->
    @socket.emit 'json', @json
    unless @scanned
      @scanMetaData()

  setSocket: (socket) ->
    @socket = socket

  check: (socket) ->
    @socket = socket if socket
    if @exists
      @emit()
    else if @target.exists
      if fs.existsSync '../cache.json'
        @exists = true
        @json = JSON.parse fs.readFileSync('../cache.json').toString()
        @emit()
      else
        @scan()
    else
      socket.emit 'promptTarget'

  save: ->
    fs.writeFileSync '../cache.json', JSON.stringify @json

  scan: ->
    scanner = new Scanner @target.target + '/'
    tracks = scanner.scan()
    totalSize = scanner.getTotalSize tracks
    @json =
      tracks: tracks
      totalSize: totalSize
      totalCnt: _.keys(tracks).length
    @save()
    @emit()

  scanMetaData: ->
    async.eachSeries _.keys(@json.tracks), ((track, callback) =>
      @getTrackMetaData track, callback
    ), (err) =>
      unless err
        console.log 'metadata scan complete. saving json...'
        @scanned = true
        @save()
      else
        console.log 'scan interrupted. saving json...'
        @save()

  getTrackMetaData: (track, callback) ->
    if @socket.diconnected
      callback true
    else if @json.tracks[track].scanned
      callback()
    else
      exec './getTrackMetaData.js "' + track + '"',
        (err, stdout, stderr) =>
          @extendTrackInfo track, JSON.parse(stdout)[0]
          callback err

  extendTrackInfo: (track, obj) ->
    _.extend @json.tracks[track], obj
    @json.tracks[track].scanned = true
    @socket.emit 'metadata', @json.tracks[track]


class Target
  constructor: ->
    @check()

  check: ->
    if fs.existsSync '../target'
      @exists = true
      process.chdir path.join __dirname, '../target'
      @target = process.cwd()
      @use()
      process.chdir __dirname

  use: ->
    app.use '/target', express.static @target

  create: (target) ->
    if target
      @target = target
      @exists = true
      fs.symlinkSync '../target', @target
      @use()


io.sockets.on 'connection', (socket) ->
  unless target?
    target = new Target()
  unless json?
    json = new Json target, socket
  else
    json.check socket

  socket.on 'target', (path) ->
    target.create path
    json.scan()

  socket.on 'disconnect', ->
    socket.disconnected = true

