app = require('express')()
server = require('http').createServer app
io = require('socket.io').listen server
fs = require 'fs'

server.listen 3001

AV = require '../public/js/nodeAurora.js'
AV.require.apply null, [
  './flac.js'
  './mp3.js'
  './aac.js'
]

player = {}
track = {}

io.set 'log level', 1
io.on 'connection', (socket) ->

  socket.on 'play', (entity) ->
    track = entity
    fs.readFile '../target/' + track.filePath, (err, data) ->
      throw err if err
      player = AV.Player.fromBuffer new Uint8Array data
      player.play()

      player.on 'duration', (time) ->
        socket.emit 'duration', time

      player.on 'progress', (currentTime) ->
        socket.emit 'progress', currentTime

      player.on 'end', ->
        socket.emit 'end'

  socket.on 'seek', (timestamp) ->
    player.seek timestamp

  socket.on 'disconnect', ->
    player.stop()
    process.exit 0

process.send
  ready: true
