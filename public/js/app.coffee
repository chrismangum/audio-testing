
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
    enableColumnResize: true
    enableColumnReordering: true
    multiSelect: false
    headerRowHeight: 24
    rowHeight: 24
    showFilter: true

  socket = io.connect 'http://localhost'
  socket.on 'metadata', (data) ->
    console.log data

  socket.on 'json', (data) ->
    $scope.data = data
    $scope.dataValues = _.values data.tracks
    console.log $scope.dataValues
    $scope.$apply()
]
