
app.controller 'player', ['$scope', ($scope) ->
  $scope.progress = 0
  $scope.player = null
  $scope.repeat = false

  $scope.toggleRepeat = ->
    switch $scope.repeat
      when false then $scope.repeat = 'all'
      when 'all' then $scope.repeat = 'one'
      when 'one' then $scope.repeat = false

  $scope.togglePlayback = ->
    if $scope.player
      $scope.player.togglePlayback()
    else
      $scope.play()

  $scope.previous = ->
    if $scope.player
      if $scope.player.currentTime > 1000
        $scope.player.seek 0
      else
        $scope.play getAdjacentTrack(-1), $scope.player.playing

  $scope.next = ->
    if $scope.player
      $scope.play getAdjacentTrack(1), $scope.player.playing

  getAdjacentTrack = (direction) ->
    $scope.getAdjacentTrack direction, $scope.player.entity, $scope.repeat

  $scope.play = (track, play = true) ->
    if track is false
      return
    if $scope.player
      delete $scope.player.entity.playing
      $scope.player.stop()
    track ?= $scope.getSelectedTrack()
    track.playing = play
    $scope.player = new Player track, $scope
    $scope.safeApply()

  $scope.$on 'play', (e, track) ->
    $scope.play track

  $(document).on 'keydown', (e) ->
    unless $scope.searchFocus
      switch e.keyCode
        when 32
          $scope.togglePlayback()
          $scope.safeApply()
          false
        when 13 then $scope.play()
        when 37
          $scope.previous()
          false
        when 39
          $scope.next()
          false
        when 48 then $scope.player?.seekToPercent 0
        when 49 then $scope.player?.seekToPercent 10
        when 50 then $scope.player?.seekToPercent 20
        when 51 then $scope.player?.seekToPercent 30
        when 52 then $scope.player?.seekToPercent 40
        when 53 then $scope.player?.seekToPercent 50
        when 54 then $scope.player?.seekToPercent 60
        when 55 then $scope.player?.seekToPercent 70
        when 56 then $scope.player?.seekToPercent 80
        when 57 then $scope.player?.seekToPercent 90
        when 187 then $scope.player?.increaseVolume()
        when 189 then $scope.player?.decreaseVolume()
]

class Player extends AV.Player
  constructor: (@entity, $scope) ->
    super AV.Asset.fromURL '/target/' + @entity.filePath
    if localStorage.volume
      @volume = parseInt localStorage.volume, 10
    if @entity.playing
      @play()
    #player events:
    @.on 'progress', (timestamp) ->
      @progress = timestamp / @duration * 100
      $scope.safeApply()
    @.on 'end', ->
      if $scope.repeat is 'one'
        $scope.play @entity
      else
        $scope.next()

  increaseVolume: (amount = 10) ->
    @volume += amount
    @volume = 100 if @volume > 100

  decreaseVolume: (amount = 10) ->
    @volume -= amount
    @volume = 0 if @volume < 0

  seekToPercent: (percent) ->
    @seek percent / 100 * @duration

  togglePlayback: ->
    @entity.playing = !@entity.playing
    super()

