
socket = io.connect 'http://localhost'
socket.on 'metadata', (data) ->
  console.log data
socket.on 'json', (data) ->
  console.log data

socket.on 'targetExists', () ->
  console.log 'target exists!'
  player = AV.Player.fromURL 'target/12 - Masser.mp3'
  window.player = player
  player.preload()
  player.on 'metadata', (data) ->
    console.log data
    #if data.coverArt
      #console.log data.coverArt.toBlobURL()
      