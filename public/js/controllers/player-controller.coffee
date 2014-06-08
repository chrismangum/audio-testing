
app.controller 'player', ['$scope', '$timeout', ($scope, $timeout) ->
  $scope.progress = 0
  $scope.player = null
  $scope.repeat = false
  $scope.playerSocket = null

  $scope.toggleShuffle = ->
    unless $scope.data.shuffledData.length
      $scope.data.shuffledData = _.shuffle $scope.gridOptions.gridData
    else
      $scope.data.shuffledData = []
    $scope.updatePlaylist()

  $scope.$watch 'gridOptions.gridData', (n, o) ->
    if n isnt o and $scope.data.shuffledData.length
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
      $scope.updatePlaylist()
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
    getAdjacentTrackInArray $scope.data.playlist, direction

  getSelectedTrack = ->
    if $scope.gridOptions.selectedItems.length
      track = $scope.gridOptions.selectedItems[0]
    else if $scope.data.shuffledData.length
      track = $scope.data.shuffledData[0]
    else if $scope.data.sortedData.length
      track = $scope.data.sortedData[0]
    else
      track = $scope.gridOptions.gridData[0]
    $scope.scrollToTrack track
    track

  $scope.play = (track, play = true) ->
      if $scope.player?.entity.playing
        $scope.player.stop()
      if track isnt false
        track ?= getSelectedTrack()
        track.playing = play
        $scope.mainSocket.emit 'spawnPlayer'
        $scope.player = new Player track, $scope
      $scope.safeApply()

  $scope.$on 'play', (e, track) ->
    $scope.play track

  $scope.createSocket = ->
    socket = io.connect 'http://localhost:3001'
    socket.on 'connect', ->
      $scope.player.play socket
    socket.on 'duration', (duration, filePath) ->
      $scope.preventPlay = false
      $scope.player.duration = duration
      $scope.player.checkSong filePath
    socket.on 'progress', (currentTime) ->
      $scope.player.setProgress currentTime
    socket.on 'end', ->
      $scope.player.end()
    socket

  $scope.mainSocket.on 'playerReady', ->
    $scope.preventPlay = true
    unless $scope.playerSocket
      $scope.playerSocket = $scope.createSocket()
    else
      $scope.playerSocket.connect()

  $(document).on 'keydown', (e) ->
    unless $scope.data.searchFocus
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

class Player
  constructor: (@entity, @scope) ->
    if localStorage.volume
      @volume = parseInt localStorage.volume, 10
    @scope.data.nowPlaying = @entity

  stop: ->
    unless @scope.preventPlay
      @scope.playerSocket.disconnect()
    delete @entity.playing

  seek: (timestamp) ->
    @scope.playerSocket.emit 'seek', timestamp

  play: ->
    if @entity.playing
      @scope.playerSocket.emit 'play', @entity, @volume

  previous: ->
    if @currentTime > 1000
      @seek 0
    else
      @scope.play @scope.getAdjacentTrack(-1), @playing

  setProgress: (currentTime) ->
    @currentTime = currentTime
    @progress = currentTime / @duration * 100
    @scope.safeApply()

  checkSong: (filePath) ->
    if filePath isnt @entity.filePath
      @play @entity

  next: ->
    @scope.play @scope.getAdjacentTrack(1), @playing

  end: ->
    if @scope.repeat is 'one'
      @scope.play @entity
    else
      @next()

  setVolume: (percent = @volume) ->
    localStorage.volume = percent
    @scope.playerSocket.emit 'volume', percent

  increaseVolume: (amount = 10) ->
    @volume += amount
    @volume = 100 if @volume > 100
    @setVolume()

  decreaseVolume: (amount = 10) ->
    @volume -= amount
    @volume = 0 if @volume < 0
    @setVolume()

  seekToPercent: (percent) ->
    @seek percent / 100 * @duration

  togglePlayback: ->
    if @entity.playing
      @stop()
    else
      @scope.play @entity


