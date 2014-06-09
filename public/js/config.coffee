window.app = angular.module 'app', ['ngRoute', 'ngGrid', 'ui.bootstrap']

app.config ['$routeProvider', '$locationProvider'
  ($routeProvider, $locationProvider) ->
    $routeProvider
      .when '/:group',
        templateUrl: (params) ->
          '/static/' + params.group + '.html'
        controller: 'tmp'
      .when '/artists/:artist',
        templateUrl: '/static/artistDetail.html'
        controller: 'tmp'
      .when '/artists/:artist/:album',
        templateUrl: '/static/albumDetail.html'
        controller: 'tmp'
      .otherwise
        templateUrl: '/static/songs.html'
        controller: 'tmp'
    $locationProvider.html5Mode true
]
