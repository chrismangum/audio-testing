
app = angular.module 'app', ['ngGrid']

app.controller 'main', ['$scope', ($scope) ->
  $scope.dataValues = []
  $scope.data = {}
  $scope.nowPlaying = false
  $scope.player = null

  $scope.gridOptions =
    columnDefs: [
      {
        field: 'title'
        cellTemplate:
          '<div class="ngCellText {{col.colIndex()}}" ng-class="{\'now-playing-indicator\': row.entity.playing}" ng-dblclick="play(row.entity)">
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
    headerRowHeight: 24
    rowHeight: 24
    selectedItems: []
    showFilter: true

  #set cellTemplate for all columns:
  _.each $scope.gridOptions.columnDefs, (col) ->
    _.defaults col,
      cellTemplate:
        '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'

  $scope.getSelectedTrack = ->
    if $scope.gridOptions.selectedItems.length
      return $scope.gridOptions.selectedItems[0]
    else
      return $scope.dataValues[0]

  $scope.togglePlayback = ->
    unless $scope.nowPlaying
      $scope.play()
    else
      $scope.player.togglePlayback()

  $scope.stop = ->
    $scope.player.stop()
    $scope.nowPlaying.playing = false

  $scope.play = (track) ->
    if $scope.player
      $scope.stop()
    unless track
      track = $scope.getSelectedTrack()
    $scope.player = AV.Player.fromURL 'target/' + track.fileName
    track.playing = true
    $scope.nowPlaying = track
    $scope.player.play()

  socket = io.connect 'http://localhost'

  socket.on 'metadata', (data) ->
    _.extend $scope.data.tracks[data.filePath], _.omit data, 'filePath'
    $scope.$apply()

  socket.on 'json', (data) ->
    $scope.data = data
    $scope.dataValues = _.values data.tracks
    $scope.$apply()
]
