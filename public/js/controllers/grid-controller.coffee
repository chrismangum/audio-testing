
app.controller 'grid', ['$scope', '$timeout', ($scope, $timeout) ->
  $scope.search = {}

  $scope.setAlbumSort = (sort) ->
    if sort is 'Artist'
      $scope.albumSort =
        name: 'Artist'
        value: ['artist', 'name']
    else if sort is 'Title'
      $scope.albumSort =
        name: 'Title'
        value: 'name'

  #default value:
  $scope.setAlbumSort 'Artist'

  updateLocalStorage = (prefs) ->
    localStorage.columnPrefs = JSON.stringify prefs or $scope.columnPrefs

  #defaults:
  unless localStorage.columnPrefs
    updateLocalStorage
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
      sortInfo:
        fields: ['artist', 'album', 'trackNumber']
        directions: ['asc', 'asc', 'asc']

  $scope.columnPrefs = JSON.parse localStorage.columnPrefs

  $scope.$watch 'search.grid', (n, o) ->
    if n isnt o
      $scope.gridOptions.filterOptions.filterText = n

  #put a throttle around this:
  $scope.$on 'ngGridEventSorted', do ->
    throttle = null
    (e, sortInfo) ->
      if throttle
        $timeout.cancel throttle
      throttle = $timeout (->
        $scope.columnPrefs.sortInfo =  _.pick sortInfo, 'fields', 'directions'
        updateLocalStorage()
        $scope.data.sortedData = $scope.gridOptions.sortedData
      ), 250

  availableColumns =
    trackNumber:
      displayName: '#'
      field: 'trackNumber'
      minWidth: 10
    title:
      field: 'title'
      cellTemplate:
        '<div class="ngCellText {{col.colIndex()}}" ng-class="{\'now-playing-indicator\': row.entity.playing, \'now-paused-indicator\': row.entity.playing === false}" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'
    artist:
      field: 'artist'
      displayName: 'Artist (Albums A-Z)'
    album:
      field: 'album'
    genre:
      field: 'genre'
    year:
      field: 'year'

  #set cellTemplate default for all columns:
  _.forEach availableColumns, (col) ->
    _.defaults col,
      cellTemplate:
        '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'
      headerCellTemplate:
        '<div class="ngHeaderSortColumn {{col.headerClass}}" ng-style="{\'cursor\': col.cursor}" ng-class="{ \'ngSorted\': !noSortVisible }">
          <div ng-click="customSort($event, col, columns)" ng-class="\'colt\' + col.index" class="ngHeaderText">{{col.displayName}}</div>
          <div class="ngSortButtonDown" ng-show="col.showSortButtonDown()"></div>
          <div class="ngSortButtonUp" ng-show="col.showSortButtonUp()"></div>
          <div ng-class="{ ngPinnedIcon: col.pinned, ngUnPinnedIcon: !col.pinned }" ng-click="togglePin(col)" ng-show="col.pinnable"></div>
        </div>
        <div ng-show="col.resizable" class="ngHeaderGrip" ng-click="col.gripClick($event)" ng-mousedown="col.gripOnMouseDown($event)"></div>'


  _.assign $scope.gridOptions,
    columnDefs: []
    data: 'gridOptions.gridData'
    filterOptions: {}
    gridData: []
    enableColumnReordering: true
    enableColumnResize: true
    headerRowHeight: 32
    rowHeight: 24
    rowTemplate:
      '<div ng-style="{ \'cursor\': row.cursor }" ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell {{col.cellClass}}">
        <div class="ngVerticalBar ngVerticalBarVisible" ng-style="{height: rowHeight}">&nbsp;</div>
        <div ng-cell></div>
      </div>'
    selectedItems: []
    showColumnMenu: true
    sortInfo: $scope.columnPrefs.sortInfo

  #set saved column order / visibility
  _.forEach $scope.columnPrefs.order, (val, i) ->
    availableColumns[val].visible = $scope.columnPrefs.visibility[val]
    $scope.gridOptions.columnDefs[i] = availableColumns[val]

  #set saved column widths
  _.forEach $scope.columnPrefs.widths, (val, key) ->
    availableColumns[key].width = val

  $scope.$on 'newColumnWidth', (e, col) ->
    availableColumns[col.field].width = col.width
    $scope.columnPrefs.widths[col.field] = col.width
    updateLocalStorage()

  $scope.$on 'newColumnOrder', (e, columns) ->
    order = _.compact _.pluck columns, 'field'
    _.forEach order, (val, i) ->
      $scope.gridOptions.columnDefs[i] = availableColumns[val]
    $scope.columnPrefs.order = order
    updateLocalStorage()

  $scope.toggleColVisibility = (col) ->
    availableColumns[col.field].visible = !col.visible
    $scope.columnPrefs.visibility[col.field] = !col.visible
    updateLocalStorage()

  $scope.$on 'selectTrack', (e, track) ->
    selectOne track
    setTimeout (->
      scrollToTrack track
    ), 1

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
    selected = _.contains $scope.gridOptions.selectedItems, track
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
    _.forEach range, (n) ->
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
      rowHeight = $scope.gridOptions.rowHeight
      trackPosition = index * rowHeight
      unless top < trackPosition + rowHeight < bottom
        if trackPosition + rowHeight > bottom and disablePageJump
          viewPort.scrollTop trackPosition + rowHeight - height
        else
          viewPort.scrollTop trackPosition

  $scope.$on 'scrollToTrack', (e, track) ->
    scrollToTrack track

  sortColumns = (e, fields) ->
    e = _.clone e
    e.shiftKey = true
    _.forEach $scope.columns, (col) ->
      if _.contains fields, col.field
        col.sort e
        true

  $scope.customSort = (e, col, columns) ->
    $scope.columns = columns
    e.shiftKey = false
    switch col.field
      when 'artist'
        col.sortDirection = 'desc'
        col.sort e
        if col.displayName is 'Artist (Albums A-Z)'
          col.displayName = 'Artist (Albums by Year)'
          sortColumns e, ['year', 'album', 'trackNumber']
        else
          col.displayName = 'Artist (Albums A-Z)'
          sortColumns e, ['album', 'trackNumber']
      when 'album'
        col.sort e
        sortColumns e, ['trackNumber']
      when 'genre'
        col.sort e
        sortColumns e, ['artist', 'album', 'trackNumber']
      when 'year'
        col.sort e
        sortColumns e, ['artist', 'album', 'trackNumber']
      else
        col.sort e

  $(document).on 'keydown', (e) ->
    unless $scope.data.searchFocus
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
