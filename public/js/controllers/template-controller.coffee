
app.controller 'tmp', ['$scope', ($scope) ->
  if $scope.data.songs.length
    $scope.sortViewData()
    $scope.checkRoute()
]
