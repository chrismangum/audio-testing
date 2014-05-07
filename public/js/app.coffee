app = angular.module 'app', ['ngGrid']

app.controller 'main', ['$scope', ($scope) ->
  $scope.dataValues = []
  $scope.data = {}
  $scope.nowPlaying = false
  $scope.player = null
  $scope.progress = 0

  $scope.gridOptions =
    columnDefs: [
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
    enableColumnReordering: true
    enableColumnResize: true
    multiSelect: false
    headerRowHeight: 26
    rowHeight: 26
    rowTemplate:
      '<div ng-style="{ \'cursor\': row.cursor }" ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell {{col.cellClass}}">
        <div class="ngVerticalBar ngVerticalBarVisible" ng-style="{height: rowHeight}">&nbsp;</div>
        <div ng-cell></div>
      </div>'
    selectedItems: []
    showFilter: true

  #set cellTemplate default for all columns:
  _.each $scope.gridOptions.columnDefs, (col) ->
    _.defaults col,
      cellTemplate:
        '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'

  getAdjacentTrack = (direction) ->
    $scope.dataValues[$scope.dataValues.indexOf($scope.nowPlaying) + direction]

  getSelectedTrack = ->
    if $scope.gridOptions.selectedItems.length
      return $scope.gridOptions.selectedItems[0]
    else
      return $scope.dataValues[0]

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
    $scope.player.on 'end', ->
      $scope.next()

  socket = io.connect location.origin

  socket.on 'metadata', (data) ->
    _.extend $scope.data.tracks[data.filePath], _.omit data, 'filePath'
    $scope.$apply()

  socket.on 'json', (data) ->
    $scope.data = data
    $scope.dataValues = _.values data.tracks
    $scope.$apply()
]

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

