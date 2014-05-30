fs = require 'fs'

AV = require '../public/js/nodeAurora.js'
AV.require.apply null, [
  './flac.js'
  './mp3.js'
  './aac.js'
]

player = {}
fs.readFile process.argv[2], (err, data) ->
  throw err if err
  player = AV.Player.fromBuffer new Uint8Array data
  player.play()
  #setTimeout (->
    #player.pause()
  #), 5000

process.on 'message', (m) ->
  player?[m.action]()
