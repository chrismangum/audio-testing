
app.controller 'player', ['$scope', ($scope) ->
  $scope.progress = 0
  $scope.player = null
  $scope.repeat = false
  $scope.shuffling = false

  $scope.toggleShuffle = ->
    $scope.shuffling = !$scope.shuffling
    if $scope.shuffling
      $scope.data.shuffledData = _.shuffle $scope.gridOptions.gridData
    else
      $scope.data.shuffledData = false

  $scope.$watch 'gridOptions.gridData', (n, o) ->
    if n isnt o and $scope.shuffling
      $scope.data.shuffledData = _.shuffle n

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

  getAdjacentTrackInArray = (array, direction) ->
    currentIndex = array.indexOf $scope.player.entity
    newIndex = currentIndex + direction
    if $scope.repeat is 'all'
      if currentIndex is array.length - 1 and direction is 1
        newIndex = 0
      else if currentIndex is 0 and direction is -1
        newIndex = array.length - 1
    $scope.scrollToTrack array[newIndex]
    array[newIndex] or false

  $scope.getAdjacentTrack = (direction) ->
    if $scope.shuffling
      getAdjacentTrackInArray $scope.data.shuffledData, direction
    else if $scope.data.sortedData.length
      getAdjacentTrackInArray $scope.data.sortedData, direction
    else
      getAdjacentTrackInArray $scope.gridOptions.gridData, direction

  getSelectedTrack = ->
    if $scope.gridOptions.selectedItems.length
      track = $scope.gridOptions.selectedItems[0]
    else if $scope.shuffling
      track = $scope.data.shuffledData[0]
    else if $scope.data.sortedData.length
      track = $scope.data.sortedData[0]
    else
      track = $scope.gridOptions.gridData[0]
    $scope.scrollToTrack track
    track

  $scope.play = (track, play = true) ->
    if track is false
      return
    if $scope.player
      delete $scope.player.entity.playing
      $scope.player.stop()
    track ?= getSelectedTrack()
    track.playing = play
    $scope.player = new Player track, $scope
    $scope.data.nowPlaying = track
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
          $scope.player.previous()
          false
        when 39
          $scope.player.next()
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
  constructor: (@entity, @scope) ->
    super AV.Asset.fromURL '/target/' + @entity.filePath
    if localStorage.volume
      @volume = parseInt localStorage.volume, 10
    if @entity.playing
      @play()
    #player events:
    @.on 'progress', (timestamp) ->
      @progress = timestamp / @duration * 100
      @scope.safeApply()
    @.on 'end', ->
      if @scope.repeat is 'one'
        @scope.play @entity
      else
        @next()

  previous: ->
    if @currentTime > 1000
      @seek 0
    else
      @scope.play @scope.getAdjacentTrack(-1), @playing

  next: ->
    @scope.play @scope.getAdjacentTrack(1), @playing

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

