
timer = null
player = AV.Player.fromURL 'static/test.m4a'

player.on 'error', (e) ->
  throw e
window.player = player
player.on 'metadata', (data) ->
  console.log data
  if data.coverArt
    console.log data.coverArt.toBlobURL()

$('.play').on 'click', ->
  player.play()
  timer = setInterval (->
    percentage = (player.currentTime / player.duration * 100) + '%'
    $('.progress-bar').css 'width', percentage
  ), 100

$('.pause').on 'click', ->
  player.pause()
  clearInterval timer
