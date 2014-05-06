
app = angular.module 'app', ['ngGrid']

app.controller 'main', ['$scope', ($scope) ->
  $scope.dataValues = []
  $scope.data = {}

  $scope.gridOptions =
    columnDefs: [
      { field: 'title' }
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
    showFilter: true

  #set cellTemplate for all columns:
  _.each $scope.gridOptions.columnDefs, (col) ->
    col.cellTemplate =
      '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity.fileName)">
        <span ng-cell-text>{{ COL_FIELD }}</span>
      </div>'

  $scope.play = (fileName) ->
    player = AV.Player.fromURL 'target/' + fileName
    player.play()
    player.on 'metadata', (data) ->
      console.log data

  socket = io.connect 'http://localhost'

  socket.on 'metadata', (data) ->
    _.extend $scope.data.tracks[data.filePath], _.omit data, 'filePath'
    $scope.$apply()

  socket.on 'json', (data) ->
    $scope.data = data
    $scope.dataValues = _.values data.tracks
    $scope.$apply()
]
