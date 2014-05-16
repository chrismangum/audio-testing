
app.controller 'grid', ['$scope', ($scope) ->
  rowHeight = 26

  $scope.$watch 'gridOptions.gridData', (n, o) ->
    if n isnt o and $scope.shuffling
      $scope.data.shuffledData = _.shuffle n

  $scope.$watch 'searchText', (n, o) ->
    if n isnt o
      $scope.gridOptions.filterOptions.filterText = n

  $scope.$on 'ngGridEventSorted', ->
    $scope.data.sortedData = $scope.gridOptions.sortedData

  availableColumns =
    trackNumber: {
      displayName: '#'
      field: 'trackNumber'
      minWidth: 10
    }
    title: {
      field: 'title'
      cellTemplate:
        '<div class="ngCellText {{col.colIndex()}}" ng-class="{\'now-playing-indicator\': row.entity.playing, \'now-paused-indicator\': row.entity.playing === false}" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'
    }
    artist: { field: 'artist' }
    album: { field: 'album' }
    genre: { field: 'genre' }
    year: { field: 'year' }

  #set cellTemplate default for all columns:
  _.each availableColumns, (col) ->
    _.defaults col,
      cellTemplate:
        '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'

  _.extend $scope.gridOptions,
    columnDefs: []
    data: 'gridOptions.gridData'
    filterOptions: {}
    gridData: []
    enableColumnReordering: true
    enableColumnResize: true
    headerRowHeight: rowHeight
    rowHeight: rowHeight
    rowTemplate:
      '<div ng-style="{ \'cursor\': row.cursor }" ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell {{col.cellClass}}">
        <div class="ngVerticalBar ngVerticalBarVisible" ng-style="{height: rowHeight}">&nbsp;</div>
        <div ng-cell></div>
      </div>'
    selectedItems: []
    showColumnMenu: true

  $scope.updateLocalStorage = (prefs) ->
    localStorage.columnPrefs = JSON.stringify prefs or $scope.columnPrefs

  unless localStorage.columnPrefs
    $scope.updateLocalStorage
      visibility:
        trackNumber: true
        title: true
        artist: true
        album: true
        genre: true
        year: true
      widths:
        trackNumber: 30
      order: [
        'trackNumber',
        'title',
        'artist',
        'album',
        'genre',
        'year'
      ]

  $scope.columnPrefs = JSON.parse localStorage.columnPrefs

  #set saved column order / visibility
  _.each $scope.columnPrefs.order, (val, i) ->
    availableColumns[val].visible = $scope.columnPrefs.visibility[val]
    $scope.gridOptions.columnDefs[i] = availableColumns[val]

  #set saved column widths
  _.each $scope.columnPrefs.widths, (val, key) ->
    availableColumns[key].width = val

  $scope.$on 'newColumnWidth', (e, col) ->
    availableColumns[col.field].width = col.width
    $scope.columnPrefs.widths[col.field] = col.width
    $scope.updateLocalStorage()

  $scope.$on 'newColumnOrder', (e, columns) ->
    order = _.compact _.pluck columns, 'field'
    _.each order, (val, i) ->
      $scope.gridOptions.columnDefs[i] = availableColumns[val]
    $scope.columnPrefs.order = order
    $scope.updateLocalStorage()

  $scope.toggleColVisibility = (col) ->
    availableColumns[col.field].visible = !col.visible
    $scope.columnPrefs.visibility[col.field] = !col.visible
    $scope.updateLocalStorage()

  selectOne = (track) ->
    if track?
      if _.isObject track
        track = getTrackPosition track
      $scope.gridOptions.selectAll false
      $scope.gridOptions.selectRow track, true

  selectAdjacentTrack = (e, direction) ->
    if $scope.gridOptions.selectedItems.length
      index = getTrackPosition $scope.gridOptions.selectedItems[0]
      endIndex = getTrackPosition $scope.gridOptions.selectedItems.slice(-1)[0]
      if e.shiftKey
        endIndex = endIndex + direction
        if $scope.gridOptions.gridData[endIndex]
          selectRange index, endIndex
          scrollToIndex endIndex, true
      else if $scope.gridOptions.selectedItems.length > 1
        selectIndex getIndexOutideBounds index, endIndex, direction
      else
        selectIndex index + direction

  getIndexOutideBounds = (a, b, direction) ->
    if direction is 1
      item = if a > b then a else b
    else
      item = if a < b then a else b
    item + direction

  selectIndex = (index) ->
    if index < 0
      index = 0
    else if index >= $scope.gridOptions.gridData.length
      index = $scope.gridOptions.gridData.length - 1
    selectOne index
    scrollToIndex index

  selectOneToggle = (track) ->
    selected = $scope.gridOptions.selectedItems.indexOf(track) isnt -1
    $scope.gridOptions.selectRow getTrackPosition(track), not selected

  getTrackPosition = (track) ->
    if $scope.data.sortedData.length
      $scope.data.sortedData.indexOf track
    else
      $scope.gridOptions.gridData.indexOf track

  selectRange = (startIndex, endIndex) ->
    if _.isObject startIndex
      startIndex = getTrackPosition startIndex
    if _.isObject endIndex
      endIndex = getTrackPosition endIndex
    if startIndex < endIndex
      range = _.range startIndex, endIndex + 1
    else
      range = _.range startIndex, endIndex - 1, -1
    $scope.gridOptions.selectAll false
    _.each range, (n) ->
      $scope.gridOptions.selectRow n, true

  $scope.selectRow = (e, track) ->
    if $scope.gridOptions.selectedItems.length
      if e.shiftKey
        return selectRange $scope.gridOptions.selectedItems[0], track
      else if e.altKey
        return selectOneToggle track
    selectOne track

  scrollToTrack = (track) ->
    if track
      if $scope.data.sortedData.length
        scrollToIndex $scope.data.sortedData.indexOf track
      else
        scrollToIndex $scope.gridOptions.gridData.indexOf track

  scrollToIndex = (index, disablePageJump) ->
    if index isnt -1
      viewPort = $ '.ngViewport'
      top = viewPort.scrollTop()
      height = viewPort.height()
      bottom = top + height
      trackPosition = index * rowHeight
      unless top < trackPosition + rowHeight < bottom
        if trackPosition + rowHeight > bottom and disablePageJump
          viewPort.scrollTop trackPosition + rowHeight - height
        else
          viewPort.scrollTop trackPosition

  $scope.$on 'scrollToTrack', (e, track) ->
    scrollToTrack track

  $(document).on 'keydown', (e) ->
    unless $scope.searchFocus
      switch e.keyCode
        when 38
          selectAdjacentTrack e, -1
          $scope.safeApply()
          false
        when 40
          selectAdjacentTrack e, 1
          $scope.safeApply()
          false
]
