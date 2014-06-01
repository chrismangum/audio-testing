
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
      $scope.player?.setVolume $scope.volume
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
      connect: 'lower'
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
