window.app = angular.module 'app', ['ngRoute', 'ngGrid', 'ui.bootstrap']

app.config ['$routeProvider', '$locationProvider'
  ($routeProvider, $locationProvider) ->
    $routeProvider
      .when '/:group',
        templateUrl: (params) ->
          '/static/' + params.group + '.html'
        controller: 'tmp'
      .when '/playlist/:playlistName',
        templateUrl: '/static/playlist.html'
        controller: 'tmp'
      .otherwise
        templateUrl: '/static/songs.html'
        controller: 'tmp'
    $locationProvider.html5Mode true
]
