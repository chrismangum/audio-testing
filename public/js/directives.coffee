
app.directive 'focusMe', ($timeout) ->
  ($scope, el, attrs) ->
    $scope.$watch attrs.focusMe, (n) ->
      if n
        $timeout ->
          el[0].focus()

app.directive 'list', ($filter) ->
  restrict: 'E'
  transclude: true
  replace: true
  template:
    '<div class="view-sidebar-list">
      <ul>
        <li class="item" ng-repeat="row in rows" ng-click="selectListItem(row.entity)" ng-class="{selected: row.entity.selected}" ng-style="{top: row.top}" ng-if="row.visible" ng-transclude></li>
      </ul>
    </div>'
  link: ($scope, el, attrs) ->
    rowHeight = 54
    $ul = el.children()
    $scope.options = $scope.$eval attrs.options
    canvasHeight = 0
    scrollBuffer = 70

    selectAdjacentListItem = (direction) ->
      if $scope.params.group
        type = $scope.params.group[0...-1]
        index = $scope.data[$scope.params.group].indexOf $scope.selectedItems[type]
        selectListItemIndex index + direction

    scrollListToIndex = (index) ->
      if index isnt -1
        view = $scope.params.group
        viewPort = $ '.view-sidebar-list'
        top = viewPort.scrollTop()
        height = viewPort.height()
        bottom = top + height
        trackPosition = index * rowHeight
        unless top < trackPosition + rowHeight < bottom
          viewPort.scrollTop trackPosition

    scrollListToItem = (item) ->
      view = $scope.params.group
      scrollListToIndex $scope.data[view].indexOf item

    selectListItemIndex = (index) ->
      view = $scope.params.group
      if index < 0
        index = 0
      else if index >= $scope.data[view].length
        index = $scope.data[view].length - 1
      item = $scope.data[view][index]
      $scope.selectListItem item
      scrollListToIndex index

    class Row
      constructor: (@entity, @top) ->

    $scope.updateRowVisibility = (canvasTop = el.scrollTop()) ->
      _.forEach $scope.rows, (row, i) ->
        bufferTop = canvasTop - scrollBuffer
        bufferBottom = canvasTop + canvasHeight + scrollBuffer
        row.visible = bufferTop < row.top < bufferBottom
        true

    calcCanvasHeight = ->
      canvasHeight = $(window).height() - 101

    calcCanvasHeight()

    $scope.$watch 'search.list', (n, o) ->
      if n isnt o
        updateDataset $filter('filter') $scope.dataArray, name: n

    updateDataset = (dataset) ->
      $ul.height rowHeight * dataset.length
      $scope.rows = _.map dataset, (item, i) ->
        new Row item, i * rowHeight
      $scope.updateRowVisibility()

    $scope.$watch $scope.options.data, (n, o) ->
      if n
        $scope.dataArray = n
        updateDataset n
        scrollListToItem $scope.selectedItems[$scope.params.group[0...-1]]

    el.on 'scroll', (e) ->
      $scope.updateRowVisibility e.target.scrollTop
      $scope.safeApply()

    $(window).on 'resize', ->
      calcCanvasHeight()
      $scope.updateRowVisibility()

    arrowKeys = (e) ->
      unless $scope.data.searchFocus
        switch e.keyCode
          when 38 #up arrow
            if $scope.data.focusedPane is 'list'
              selectAdjacentListItem -1
              $scope.safeApply()
            false
          when 40 #down arrow
            if $scope.data.focusedPane is 'list'
              selectAdjacentListItem 1
              $scope.safeApply()
            false

    $(document).on 'keydown', arrowKeys
    $scope.$on '$destroy', ->
      $(document).off 'keydown', arrowKeys

app.directive 'volumeSlider', ($storage) ->
  restrict: 'E'
  template:
    '<div class="volume" ng-click="showSlider = !showSlider">
      <button class="button">
        <span ng-if="muted" ng-click="toggleMute()" class="icon-mute"></span>
        <span ng-if="!muted" ng-click="toggleMute()" ng-class="{
          \'icon-volume-high\': volume > 66,
          \'icon-volume-medium\': volume > 33 && volume <= 66,
          \'icon-volume-low\': volume > 0 && volume <= 33,
          \'icon-volume-off\': !volume
        }"></span>
      </button>
      <div ng-class="{show: showSlider}">
        <div class="volume-slider"></div>
      </div>
    </div>'
  replace: true
  link: ($scope, el, attrs) ->
    $scope.showSlider = false
    $scope.volume = parseInt $storage.volume, 10
    $scope.muted = false

    $scope.toggleMute = ->
      $scope.muted = !$scope.muted
      if $scope.muted
        $scope.volume = 0
        updateVolume true, false
      else
        $scope.volume = parseInt $storage.volume, 10
        updateVolume true, false

    increaseVolume = (amount = 10) ->
      $scope.volume += amount
      $scope.volume = 100 if $scope.volume > 100
      updateVolume true

    decreaseVolume = (amount = 10) ->
      $scope.volume -= amount
      $scope.volume = 0 if $scope.volume < 0
      updateVolume true

    updateVolume = (setSlider, save = true) ->
      if setSlider
        slider.val $scope.volume
      $scope.player?.setVolume $scope.volume
      if save
        $storage.volume = $scope.volume
        $storage.save()
      $scope.safeApply()

    setVolume = ->
      $scope.volume = parseInt $(@).val(), 10
      updateVolume()

    slider = el
      .find '.volume-slider'
      .noUiSlider
        start: $scope.volume
        orientation: 'horizontal'
        connect: 'lower'
        range:
          'min': 0
          'max': 100
      .on 'slide', setVolume
      .on 'set', setVolume

    $scope.$watch 'player.volume', (n, o) ->
      if n isnt o
        $scope.volume = n
        slider.val n

    $(document).on 'keydown', (e) ->
      unless $scope.data.searchFocus
        switch e.keyCode
          when 187 then increaseVolume()
          when 189 then decreaseVolume()

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
        el.val n or 0
