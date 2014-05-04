
#player = AV.Player.fromURL 'target/12 - Masser.mp3'
#player.on 'metadata', (data) ->
  #console.log data
  #if data.coverArt
    #console.log data.coverArt.toBlobURL()

socket = io.connect 'http://localhost'

$(window).on("resize", ->
  $(".main").css height: ($(window).height()) + "px"
  return
).resize()