
player = null
timer = null

document.querySelector("input[type=file]").onchange = (e) ->
  if player
    player.stop()
  player = AV.Player.fromFile e.target.files[0]
  player.on 'error', (e) ->
    throw e
  console.log player
  player.on 'metadata', (data) ->
    console.log data
    if data.coverArt
      console.log data.coverArt.toBlobURL()

$('.play').on('click', ->
  player.play()
  timer = setInterval (->
    percentage = (player.currentTime / player.duration * 100) + '%'
    $('.progress-bar').css 'width', percentage
  ), 100)

$('.pause').on 'click', ->
  player.pause()
  clearInterval timer
