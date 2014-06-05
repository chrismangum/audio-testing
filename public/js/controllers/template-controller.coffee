
app.controller 'tmp', ['$scope', ($scope) ->
  if $scope.data.songs.length
    $scope.sortViewData()
    $scope.checkRoute()

  $scope.listOptions =
    data: 'data.' + $scope.params.group
]
