express = require 'express'
path = require 'path'
fs = require 'fs'
_ = require 'lodash'
app = express()
async = require 'async'
cp = require 'child_process'
server = require('http').createServer app
io = require('socket.io').listen server
readline = require 'readline'

target = null
json = null

server.listen 3000
process.chdir __dirname

app.use express.logger 'dev'
app.set 'json spaces', 0
app.use '/static', express.static '../public'
app.use '/target', express.static '../target'
app.get '*', (req, res) ->
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
      totalSize += track.fileSize
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
          title: item,
          fileSize: stat.size
          filePath: (filePath + item).replace @filePath, ''
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
    else
      if fs.existsSync '../cache.json'
        @exists = true
        @json = JSON.parse fs.readFileSync('../cache.json').toString()
        @emit()
      else if @target.exists
        @scan()
      else
        @target.prompt =>
          @scan()

  save: ->
    fs.writeFileSync '../cache.json', JSON.stringify @json

  scan: ->
    scanner = new Scanner '../target/'
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
    if @socket.disconnected
      callback true
    else if @json.tracks[track].scanned
      callback()
    else
      cp.exec 'node ./getTrackMetaData.js "' + track + '"',
        (err, stdout, stderr) =>
          if err
            console.log stderr
          else if stdout.length
            @extendTrackInfo track, JSON.parse(stdout)[0]
          callback()

  extendTrackInfo: (track, obj) ->
    _.extend @json.tracks[track], obj
    @json.tracks[track].scanned = true
    obj.filePath = track
    @socket.emit 'metadata', obj

class Target
  constructor: ->
    @check()

  check: ->
    if fs.existsSync '../target'
      @exists = true

  prompt: (callback) ->
    unless @iface
      @iface = readline.createInterface
        input: process.stdin
        output: process.stdout
    @iface.question 'Please enter media directory:', (target) =>
      if fs.existsSync target
        @create target
        callback()
      else
        @prompt callback

  create: (target) ->
    if target
      @exists = true
      fs.symlinkSync target, '../target'

io.set 'log level', 1
io.sockets.on 'connection', (socket) ->
  player = null

  unless target?
    target = new Target()
  unless json?
    json = new Json target, socket
  else
    json.check socket

  socket.on 'spawnPlayer', ->
    player = cp.fork './player.js'
    player.on 'message', (m) ->
      if m.ready
        socket.emit 'playerReady'

  socket.on 'disconnect', ->
    socket.disconnected = true


