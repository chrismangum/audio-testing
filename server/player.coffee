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

io.on 'connection', (socket) ->
  socket.on 'play', (entity) ->
    track = entity
    fs.readFile '../target/' + track.filePath, (err, data) ->
      throw err if err
      player = AV.Player.fromBuffer new Uint8Array data
      player.play()

  socket.on 'stop', () ->
    player.stop()
    process.exit 0

process.send
  ready: true
