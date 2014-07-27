
app.controller 'grid', ['$scope', '$timeout', '$storage', ($scope, $timeout, $storage) ->
  updatePlaylist = false
  $scope.search = {}

  $scope.toggleFocusedPane = ->
    $scope.data.focusedPane = switch $scope.data.focusedPane
      when 'list' then 'grid'
      else 'list'

  $scope.$watch 'search.grid', (n, o) ->
    if n isnt o
      $scope.gridOptions.filterOptions.filterText = n

  $scope.$on 'ngGridEventSorted', do ->
    throttle = null
    (e, sortInfo) ->
      if throttle
        $timeout.cancel throttle
      throttle = $timeout (->
        sortInfo.columns[0].isSorted = true
        $storage.columnPrefs.sortInfo =  _.pick sortInfo, 'fields', 'directions'
        $storage.save()
        $scope.data.sortedData = $scope.gridOptions.sortedData
        if updatePlaylist
          $scope.updatePlaylist()
          updatePlaylist = false
        if $scope.data.songToSelect
          if _.isObject $scope.data.songToSelect
            $scope.selectTrack $scope.data.songToSelect
          else
            $scope.selectIndex 0
          $scope.data.songToSelect = false
      ), 250


  ### NG Grid Options ###
  _.assign $scope.gridOptions,
    columnDefs: []
    data: 'gridOptions.gridData'
    filterOptions: {}
    gridData: []
    enableColumnReordering: true
    enableColumnResize: true
    headerRowHeight: 28
    rowHeight: 24
    noTabInterference: true
    rowTemplate:
      '<div ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell {{col.cellClass}}">
        <div class="ngVerticalBar ngVerticalBarVisible" ng-style="{height: rowHeight}">&nbsp;</div>
        <div ng-cell></div>
      </div>'
    selectedItems: []
    showColumnMenu: true
    sortInfo: $storage.columnPrefs.sortInfo

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
      displayName: $storage.columnPrefs.artistColumn
      isSorted: true
    album:
      field: 'album'
    genre:
      field: 'genre'
    year:
      field: 'year'

  #set cellTemplate default for all columns:
  for key, col of availableColumns
    _.defaults col,
      cellTemplate:
        '<div class="ngCellText" ng-class="col.colIndex()" ng-dblclick="play(row.entity)">
          <span ng-cell-text>{{ COL_FIELD }}</span>
        </div>'
      headerCellTemplate:
        '<div class="ngHeaderSortColumn" ng-class="{ \'ngSorted\': col.isSorted }">
          <div ng-click="customSort($event, col, columns)" ng-class="\'colt\' + col.index" class="ngHeaderText">{{col.displayName}}</div>
          <div class="ngSortButtonDown" ng-show="col.isSorted && col.showSortButtonDown()" ng-click="customSort($event, col, columns, true)"></div>
          <div class="ngSortButtonUp" ng-show="col.isSorted && col.showSortButtonUp()" ng-click="customSort($event, col, columns, true)"></div>
          <div ng-class="{ ngPinnedIcon: col.pinned, ngUnPinnedIcon: !col.pinned }" ng-click="togglePin(col)" ng-show="col.pinnable"></div>
        </div>
        <div ng-show="col.resizable" class="ngHeaderGrip" ng-click="col.gripClick($event)" ng-mousedown="col.gripOnMouseDown($event)"></div>'

  #set saved column visibility and order
  for val, i in $storage.columnPrefs.order
    availableColumns[val].visible = $storage.columnPrefs.visibility[val]
    $scope.gridOptions.columnDefs[i] = availableColumns[val]

  #set saved column widths
  for key, val of $storage.columnPrefs.widths
    availableColumns[key].width = val

  $scope.toggleColVisibility = (col) ->
    availableColumns[col.field].visible = !col.visible
    $storage.columnPrefs.visibility[col.field] = !col.visible
    $storage.save()

  $scope.$on 'newColumnWidth', (e, col) ->
    availableColumns[col.field].width = col.width
    $storage.columnPrefs.widths[col.field] = col.width
    $storage.save()

  $scope.$on 'newColumnOrder', (e, columns) ->
    $storage.columnPrefs.order = for column, i in columns
      $scope.gridOptions.columnDefs[i] = availableColumns[column.field]
      column.field
    $storage.save()


  ### Grid Selection ###
  $scope.selectIndex = (index) ->
    selectOne index
    setTimeout (->
      scrollToIndex index
    ), 1

  $scope.selectTrack = (track) ->
    selectOne track
    setTimeout (->
      scrollToTrack track
    ), 1

  selectOne = (track) ->
    if track?
      if _.isObject track
        index = getTrackPosition track
      else
        index = track
        track = getTrackAtPosition index
      $scope.gridOptions.selectAll false
      $scope.gridOptions.selectRow index, true

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
    selected = track in $scope.gridOptions.selectedItems
    $scope.gridOptions.selectRow getTrackPosition(track), not selected

  getTrackAtPosition = (index) ->
    if $scope.data.sortedData.length
      $scope.data.sortedData[0]
    else
      $scope.gridOptions.gridData[0]

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
    for n in range
      $scope.gridOptions.selectRow n, true

  $scope.selectRow = (e, track) ->
    $scope.data.focusedPane = 'grid'
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


  ### Column Sorting ###
  sortColumns = (e, fields) ->
    e = _.clone e
    e.shiftKey = true
    for field in fields
      _.find($scope.columns, field: field).sort e

  $scope.customSort = (e, col, columns, toggleDirection) ->
    updatePlaylist = true
    for column in columns
      delete column.isSorted
    col.isSorted = true
    $scope.columns = columns
    e.shiftKey = false
    switch col.field
      when 'artist'
        if toggleDirection
          col.sort e
          if col.displayName is 'Artist (Albums A-Z)'
            sortColumns e, ['album', 'trackNumber']
          else
            sortColumns e, ['year', 'album', 'trackNumber']
        else
          col.sortDirection = switch col.sortDirection
            when 'desc' then 'asc'
            else 'desc'
          col.sort e
          if col.displayName is 'Artist (Albums A-Z)'
            col.displayName = 'Artist (Albums by Year)'
            availableColumns.artist.displayName = 'Artist (Albums by Year)'
            $storage.columnPrefs.artistColumn = 'Artist (Albums by Year)'
            sortColumns e, ['year', 'album', 'trackNumber']
          else
            col.displayName = 'Artist (Albums A-Z)'
            availableColumns.artist.displayName = 'Artist (Albums A-Z)'
            $storage.columnPrefs.artistColumn = 'Artist (Albums A-Z)'
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
        when 9 #tab
          $scope.toggleFocusedPane()
          $scope.safeApply()
          false
        when 38 #up arrow
          if $scope.data.focusedPane is 'grid'
            selectAdjacentTrack e, -1
            $scope.safeApply()
          false
        when 40 #down arrow
          if $scope.data.focusedPane is 'grid'
            selectAdjacentTrack e, 1
            $scope.safeApply()
          false
]
