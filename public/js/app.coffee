app = angular.module 'app', ['ngRoute', 'ngGrid']

app.config ['$routeProvider', ($routeProvider) ->
  routeObj =
    template: '<div class="media-list" ng-grid="gridOptions"></div>'
    controller: 'tmp'
  $routeProvider
    .when '/:group', routeObj
    .otherwise routeObj
]

app.controller 'tmp', ['$scope', '$routeParams',
  ($scope, $routeParams) ->
    if $routeParams.group
      $scope.gridOptions.groups = [$routeParams.group]
    else
      $scope.gridOptions.groups = []
]

app.controller 'main', ['$scope', ($scope) ->
  rowHeight = 26
  $scope.dataValues = []
  $scope.data = {}
  $scope.nowPlaying = false
  $scope.player = null
  $scope.progress = 0
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

  $scope.gridOptions =
    columnDefs: [
      {
        displayName: '#'
        field: 'trackNumber'
        minWidth: 10
        width: 30
      }
      {
        field: 'title'
        cellTemplate:
          '<div class="ngCellText {{col.colIndex()}}" ng-class="{\'now-playing-indicator\': row.entity.playing, \'now-paused-indicator\': row.entity.paused}" ng-dblclick="play(row.entity)">
            <span ng-cell-text>{{ COL_FIELD }}</span>
          </div>'
      }
      { field: 'artist' }
      { field: 'album' }
      { field: 'genre' }
    ]
    data: 'dataValues'
    filterOptions: {}
    enableColumnReordering: true
    enableColumnResize: true
    multiSelect: false
    headerRowHeight: rowHeight
    rowHeight: rowHeight
    rowTemplate:
      '<div ng-style="{ \'cursor\': row.cursor }" ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell {{col.cellClass}}">
        <div class="ngVerticalBar ngVerticalBarVisible" ng-style="{height: rowHeight}">&nbsp;</div>
        <div ng-cell></div>
      </div>'
    selectedItems: []
    showColumnMenu: true

  #set cellTemplate default for all columns:
  _.each $scope.gridOptions.columnDefs, (col) ->
    _.defaults col,
      cellTemplate:
        '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'

  getAdjacentTrackInArray = (array, direction) ->
    index = array.indexOf($scope.nowPlaying) + direction
    if $scope.shuffling
      if $scope.sortedData
        scrollToIndex $scope.sortedData.indexOf array[index]
      else
        scrollToIndex $scope.dataValues.indexOf array[index]
    else
      scrollToIndex index
    array[index] or false

  scrollToIndex = (index) ->
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

  getSelectedTrack = ->
    if $scope.gridOptions.selectedItems.length
      $scope.gridOptions.selectedItems[0]
    else if $scope.shuffling
      if $scope.sortedData
        scrollToIndex $scope.sortedData.indexOf $scope.shuffledData[0]
      else
        scrollToIndex $scope.dataValues.indexOf $scope.shuffledData[0]
      $scope.shuffledData[0]
    else
      scrollToIndex 0
      $scope.dataValues[0]

  stop = ->
    $scope.nowPlaying.playing = false
    $scope.nowPlaying.paused = false
    $scope.player.stop()

  $scope.safeApply = ->
    unless $scope.$$phase
      $scope.$apply()

  $scope.togglePlayback = ->
    unless $scope.nowPlaying
      $scope.play()
    else
      $scope.player.togglePlayback()
      if $scope.nowPlaying.playing
        $scope.nowPlaying.playing = false
        $scope.nowPlaying.paused = true
      else
        $scope.nowPlaying.playing = true
        $scope.nowPlaying.paused = false

  $scope.previous = ->
    if $scope.player.currentTime > 1000
      $scope.player.seek 0
    else
      $scope.play getAdjacentTrack -1

  $scope.next = ->
    $scope.play getAdjacentTrack 1

  $scope.play = (track) ->
    if track is false
      return
    if $scope.player
      stop()
    unless track
      track = getSelectedTrack()
    $scope.player = AV.Player.fromURL 'target/' + track.filePath
    track.playing = true
    $scope.nowPlaying = track
    $scope.player.play()
    $scope.player.on 'progress', (timestamp) ->
      $scope.progress = (timestamp / $scope.player.duration) * 100
      $scope.safeApply()
    $scope.player.on 'metadata', (data) ->
      if data.coverArt
        $scope.nowPlaying.coverArtURL = data.coverArt.toBlobURL()
        $scope.safeApply()
    $scope.player.on 'end', ->
      $scope.next()

  socket = io.connect location.origin

  socket.on 'metadata', (data) ->
    _.extend $scope.data.tracks[data.filePath], _.omit data, 'filePath'
    $scope.safeApply()

  socket.on 'json', (data) ->
    $scope.data = data
    $scope.dataValues = _.values data.tracks
    $scope.safeApply()
]

app.directive 'nowPlayingArtwork', ->
  restrict: 'E'
  template: '<div class="now-playing-artwork"><img ng-show="nowPlaying.coverArtURL"></div>'
  replace: true
  link: ($scope, el, attrs) ->
    img = el.children()
    $scope.$watch 'nowPlaying.coverArtURL', (n, o) ->
      if n isnt o and n
        img[0].src = n

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

