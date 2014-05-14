app = angular.module 'app', ['ngRoute', 'ngGrid']

app.config ['$routeProvider', '$locationProvider'
  ($routeProvider, $locationProvider) ->
    $routeProvider
      .when '/:group',
        templateUrl: (params) ->
          'static/' + params.group + '.html'
        controller: 'tmp'
      .otherwise
        templateUrl: 'static/songs.html'
        controller: 'tmp'
    $locationProvider.html5Mode true
]

app.controller 'tmp', ['$scope', '$routeParams'
  ($scope, $routeParams) ->
    if $routeParams.group
      $scope.gridOptions.groups = [$routeParams.group.replace /\w$/, '']
    else
      $scope.gridOptions.groups = []
]

class Player extends AV.Player
  constructor: (@entity, $scope) ->
    super AV.Asset.fromURL 'target/' + @entity.filePath
    if localStorage.volume
      @volume = parseInt localStorage.volume, 10
    if @entity.playing
      @play()
    #player events:
    @.on 'progress', (timestamp) ->
      @progress = timestamp / @duration * 100
      $scope.safeApply()
    @.on 'metadata', (data) ->
      if data.coverArt
        @entity.coverArtURL = data.coverArt.toBlobURL()
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


app.controller 'main', ['$scope', ($scope) ->
  rowHeight = 26
  $scope.dataValues = []
  $scope.data = {}
  $scope.player = null
  $scope.progress = 0
  $scope.repeat = false
  $scope.shuffling = false

  $scope.shuffle = ->
    $scope.shuffling = !$scope.shuffling
    if $scope.shuffling
      $scope.shuffledData = _.shuffle $scope.dataValues
    else
      $scope.shuffledData = false

  $scope.$watch 'searchText', (n, o) ->
    if n isnt o
      $scope.gridOptions.filterOptions.filterText = n

  $scope.$on 'ngGridEventSorted', ->
    $scope.sortedData = $scope.gridOptions.sortedData

  availableColumns =
    trackNumber: {
      displayName: '#'
      field: 'trackNumber'
      minWidth: 10
    }
    title: {
      field: 'title'
      cellTemplate:
        '<div class="ngCellText {{col.colIndex()}}" ng-class="{\'now-playing-indicator\': row.entity.playing, \'now-paused-indicator\': row.entity.playing === false}" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'
    }
    artist: { field: 'artist' }
    album: { field: 'album' }
    genre: { field: 'genre' }

  #set cellTemplate default for all columns:
  _.each availableColumns, (col) ->
    _.defaults col,
      cellTemplate:
        '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'

  $scope.gridOptions =
    columnDefs: []
    data: 'dataValues'
    filterOptions: {}
    enableColumnReordering: true
    enableColumnResize: true
    headerRowHeight: rowHeight
    rowHeight: rowHeight
    selectRow: (rowIndex, state) ->
      console.log rowIndex, state
    selectItem: (rowIndex, state) ->
      console.log rowIndex, state
    rowTemplate:
      '<div ng-style="{ \'cursor\': row.cursor }" ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell {{col.cellClass}}">
        <div class="ngVerticalBar ngVerticalBarVisible" ng-style="{height: rowHeight}">&nbsp;</div>
        <div ng-cell></div>
      </div>'
    selectedItems: []
    showColumnMenu: true

  selectOne = (track, clear = true) ->
    if clear
      $scope.gridOptions.selectAll false
    else if $scope.gridOptions.selectedItems.indexOf(track) isnt -1
      $scope.gridOptions.selectItem $scope.dataValues.indexOf(track), false
      return
    $scope.gridOptions.selectItem $scope.dataValues.indexOf(track), true

  selectRange = (startTrack, endTrack) ->
    if $scope.sortedData
      startIndex = $scope.sortedData.indexOf startTrack
      endIndex = $scope.sortedData.indexOf endTrack
    else
      startIndex = $scope.dataValues.indexOf startTrack
      endIndex = $scope.dataValues.indexOf endTrack
    if startIndex < endIndex
      range = _.range startIndex, endIndex + 1
    else
      range = _.range startIndex, endIndex - 1, -1
    $scope.gridOptions.selectAll false
    _.each range, (n) ->
      $scope.gridOptions.selectRow n, true

  $scope.selectRow = (e, track) ->
    if $scope.gridOptions.selectedItems.length
      if e.shiftKey
        selectRange $scope.gridOptions.selectedItems[0], track
      else if e.altKey
        selectOne track, false
      else
        selectOne track
    else
      selectOne track

  $scope.updateLocalStorage = (prefs) ->
    localStorage.columnPrefs = JSON.stringify prefs or $scope.columnPrefs

  unless localStorage.columnPrefs
    $scope.updateLocalStorage
      visibility:
        trackNumber: true
        title: true
        artist: true
        album: true
        genre: true
      widths:
        trackNumber: 30
      order: [
        "trackNumber",
        "title",
        "artist",
        "album",
        "genre"
      ]

  $scope.columnPrefs = JSON.parse localStorage.columnPrefs

  #set saved column order / visibility
  _.each $scope.columnPrefs.order, (val, i) ->
    availableColumns[val].visible = $scope.columnPrefs.visibility[val]
    $scope.gridOptions.columnDefs[i] = availableColumns[val]

  #set saved column widths
  _.each $scope.columnPrefs.widths, (val, key) ->
    availableColumns[key].width = val

  $scope.$on 'newColumnWidth', (e, col) ->
    availableColumns[col.field].width = col.width
    $scope.columnPrefs.widths[col.field] = col.width
    $scope.updateLocalStorage()

  $scope.$on 'newColumnOrder', (e, columns) ->
    order = _.compact _.pluck columns, 'field'
    _.each order, (val, i) ->
      $scope.gridOptions.columnDefs[i] = availableColumns[val]
    $scope.columnPrefs.order = order
    $scope.updateLocalStorage()

  $scope.toggleColVisibility = (col) ->
    availableColumns[val].visible = !col.visible
    $scope.columnPrefs.visibility[col.field] = !col.visible
    $scope.updateLocalStorage()

  getAdjacentTrackInArray = (array, direction) ->
    currentIndex = array.indexOf $scope.player.entity
    newIndex = currentIndex + direction
    if $scope.repeat is 'all'
      if currentIndex is array.length - 1
        newIndex = 0
      else if currentIndex is 0
        newIndex = array.length - 1
    scrollToTrack array[newIndex]
    array[newIndex] or false

  scrollToTrack = (track) ->
    if track
      if $scope.sortedData
        scrollToIndex $scope.sortedData.indexOf track
      else
        scrollToIndex $scope.dataValues.indexOf track

  scrollToIndex = (index) ->
    if index isnt -1
      viewPort = $ '.ngViewport'
      top = viewPort.scrollTop()
      height = viewPort.height()
      bottom = top + height
      trackPosition = index * rowHeight
      unless top < trackPosition + rowHeight < bottom
        viewPort.scrollTop trackPosition

  getAdjacentTrack = (direction) ->
    if $scope.shuffling
      getAdjacentTrackInArray $scope.shuffledData, direction
    else if $scope.sortedData
      getAdjacentTrackInArray $scope.sortedData, direction
    else
      getAdjacentTrackInArray $scope.dataValues, direction

  $scope.toggleRepeat = ->
    switch $scope.repeat
      when false then $scope.repeat = 'all'
      when 'all' then $scope.repeat = 'one'
      when 'one' then $scope.repeat = false

  getSelectedTrack = ->
    if $scope.gridOptions.selectedItems.length
      track = $scope.gridOptions.selectedItems[0]
    else if $scope.shuffling
      track = $scope.shuffledData[0]
    else if $scope.sortedData
      track = $scope.sortedData[0]
    else
      track = $scope.dataValues[0]
    scrollToTrack track
    track

  $scope.safeApply = (fn) ->
    unless $scope.$$phase
      $scope.$apply fn

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

  $scope.play = (track, play = true) ->
    if track is false
      return
    if $scope.player
      delete $scope.player.entity.playing
      $scope.player.stop()
    track ?= getSelectedTrack()
    track.playing = play
    $scope.player = new Player track, $scope
    $scope.safeApply()

  socket = io.connect location.origin

  socket.on 'metadata', (data) ->
    _.extend $scope.data.tracks[data.filePath], _.omit data, 'filePath'
    $scope.safeApply()

  socket.on 'json', (data) ->
    $scope.data = data
    $scope.dataValues = _.values data.tracks
    $scope.safeApply()

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

app.directive 'nowPlayingArtwork', ->
  restrict: 'E'
  template: '<div class="now-playing-artwork"><img ng-show="player.entity.coverArtURL"></div>'
  replace: true
  link: ($scope, el, attrs) ->
    img = el.children()
    $scope.$watch 'player.entity.coverArtURL', (n, o) ->
      if n isnt o and n
        img[0].src = n


app.directive 'volumeSlider', ->
  restrict: 'E'
  template:
    '<div class="dropdown-wrapper volume-dropdown" ng-click="showSlider = !showSlider">
      <button class="button dropdown-toggle">
        <span ng-class="{\'icon-volume-high\': volume > 66, \'icon-volume-medium\': volume > 33 && volume <= 66, \'icon-volume-low\': volume > 0 && volume <= 33, \'icon-volume-off\': !volume}"></span>
      </button>
      <div class="dropdown" ng-class="{show: showSlider}">
        <div class="volume-slider"></div>
      </div>
    </div>'
  replace: true
  link: ($scope, el, attrs) ->
    $scope.showSlider = false
    $scope.volume = localStorage.volume or 100

    setVolume = ->
      $scope.volume = 100 - $(@).val()
      $scope.player?.volume = $scope.volume
      localStorage.volume = $scope.volume
      $scope.safeApply()

    slider = el
      .find '.volume-slider'
      .noUiSlider
        start: 100 - $scope.volume
        orientation: 'vertical'
        connect: 'lower'
        range:
          'min': 0
          'max': 100
      .on 'slide', setVolume
      .on 'set', setVolume

    $scope.$watch 'player.volume', (n, o) ->
      if n isnt o
        $scope.volume = n
        slider.val 100 - n

app.directive 'slider', ->
  restrict: 'E'
  link: ($scope, el, attrs) ->
    sliding = false
    sliderOptions =
      start: 0
      connect: "lower"
      range:
        'min': 0
        'max': 398203

    el.noUiSlider sliderOptions

    el.on 'slide', ->
      sliding = true

    el.on 'set', ->
      sliding = false
      $scope.player.seek parseInt $(@).val(), 10

    $scope.$watch 'player.duration', (n, o) ->
      if n and n isnt o
        sliderOptions.range.max = n
        el.noUiSlider sliderOptions, true

    $scope.$watch 'player.currentTime', (n, o) ->
      if n isnt o and not sliding
        el.val n

app.filter 'convertTimestamp', ->
  padTime = (n) ->
    if n < 10
      n = '0' + n
    return n

  (s = 0) ->
    ms = s % 1000
    s = (s - ms) / 1000
    secs = s % 60
    s = (s - secs) / 60
    mins = s % 60
    hrs = (s - mins) / 60
    if hrs
      return hrs + ':' + padTime mins + ':' + padTime secs
    else
      return mins + ':' + padTime secs

