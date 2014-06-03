fs = require 'fs'
io = require('socket.io')()
io.listen 3001

AV = require '../public/js/nodeAurora.js'
AV.require.apply null, [
  './flac.js'
  './mp3.js'
  './aac.js'
]

player = {}
track = {}

io.on 'connection', (socket) ->
  socket.on 'play', (entity, volume = 100) ->
    track = entity
    fs.readFile '../target/' + track.filePath, (err, data) ->
      throw err if err
      player.stop?()
      player = AV.Player.fromBuffer data
      player.volume = volume
      player.play()

      player.on 'duration', (time) ->
        socket.emit 'duration', time, track.filePath

      player.on 'progress', (currentTime) ->
        socket.emit 'progress', currentTime

      player.on 'end', ->
        socket.emit 'end'

  socket.on 'volume', (percent) ->
    player.volume = percent

  socket.on 'seek', (timestamp) ->
    player.seek timestamp

  socket.on 'disconnect', ->
    player.stop?()
    process.exit 0

process.send
  ready: true
