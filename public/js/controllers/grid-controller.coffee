class Row
  constructor: (@entity, @rowTop) ->

  getClasses: ->
    selected: @entity.selected

  getStyles: ->
    top: @rowTop

app.directive 'list', ->
  restrict: 'E'
  transclude: true
  replace: true
  template: '
    <div class="view-sidebar-list">
      <ul>
        <li class="item" ng-repeat="row in renderedRows", ng-click="selectListItem(row.entity)", ng-class="row.getClasses()" ng-style="row.getStyles()" ng-transclude></li>
      </ul>
    </div>'
  link: ($scope, el, attrs) ->
    rowHeight = 54
    $ul = el.children()
    $scope.options = $scope.$eval attrs.options
    $scope.rows = []
    $scope.renderedRows = []
    scrollTimer = null
    canvasHeight = 0
    scrollBuffer = 70

    $scope.safeApply = () ->
      unless $scope.$root.$$phase
        $scope.$digest()

    $scope.getVisibleRows = (canvasTop) ->
      _.filter $scope.rows, (row, i) ->
        (canvasTop - scrollBuffer) < (i * rowHeight) < (canvasTop + canvasHeight + scrollBuffer)

    $scope.renderRows = (canvasTop = el.scrollTop()) ->
      $scope.renderedRows.length = 0
      visibleRows = $scope.getVisibleRows canvasTop
      _.each visibleRows, (row, i) ->
        rowTop = $scope.rows.indexOf(row) * rowHeight
        $scope.renderedRows[i] = new Row row, rowTop

    $scope.$watch $scope.options.data, (n, o) ->
      $scope.rows = n
      $scope.renderRows()
      $ul.height rowHeight * n.length

    el.bind 'scroll', (e) ->
      $scope.renderRows e.target.scrollTop
      $scope.safeApply()

    calcCanvasHeight = ->
      canvasHeight = $(window).height() - 101

    calcCanvasHeight()
    $(window).on 'resize', calcCanvasHeight

app.controller 'grid', ['$scope', '$timeout', ($scope, $timeout) ->
  songToSelect = false
  $scope.search = {}

  $scope.toggleFocusedPane = ->
    $scope.data.focusedPane = switch $scope.data.focusedPane
      when 'list' then 'grid'
      else 'list'


  ### List Functions ###
  $scope.selectAdjacentListItem = (direction) ->
    if $scope.params.group
      type = $scope.params.group[0...-1]
      index = $scope.data[$scope.params.group].indexOf $scope.selectedItems[type]
      selectListItemIndex index + direction

  scrollListToIndex = (index) ->
    if index isnt -1
      view = $scope.params.group
      viewPort = $ '.view-sidebar-list ul'
      top = viewPort.scrollTop()
      height = viewPort.height()
      bottom = top + height
      rowHeight = 57
      trackPosition = index * rowHeight
      unless top < trackPosition + rowHeight < bottom
        viewPort.scrollTop trackPosition

  selectListItemIndex = (index) ->
    view = $scope.params.group
    if index < 0
      index = 0
    else if index >= $scope.data[view].length
      index = $scope.data[view].length - 1
    $scope.selectListItem $scope.data[view][index]
    scrollListToIndex index

  $scope.selectListItem = (item, song = true) ->
    $scope.data.focusedPane = 'list'
    type = $scope.params.group[0...-1]
    songToSelect = song
    if $scope.selectedItems[type]
      $scope.selectedItems[type].selected = false
    item.selected = true
    $scope.selectedItems[type] = item
    $scope.filterData item.songs

  $scope.$on 'selectListItem', (e, item, song) ->
    $scope.selectListItem item, song


  ### Grid Preferences ###
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

  $scope.$on 'ngGridEventSorted', do ->
    throttle = null
    (e, sortInfo) ->
      if throttle
        $timeout.cancel throttle
      throttle = $timeout (->
        $scope.columnPrefs.sortInfo =  _.pick sortInfo, 'fields', 'directions'
        updateLocalStorage()
        $scope.data.sortedData = $scope.gridOptions.sortedData
        if songToSelect
          if _.isObject songToSelect
            $scope.selectTrack songToSelect
          else
            $scope.selectIndex 0
          songToSelect = false
      ), 250


  ### NG Grid Options ###
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
    headerRowHeight: 28
    rowHeight: 24
    noTabInterference: true
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


  ### Grid Selection ###
  $scope.$on 'selectIndex', (e, index, focus) ->
    selectOne index, focus
    setTimeout (->
      scrollToIndex index
    ), 1

  $scope.$on 'selectTrack', (e, track) ->
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
    selected = _.contains $scope.gridOptions.selectedItems, track
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
    _.forEach range, (n) ->
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
    _.forEach fields, (field) ->
      _.find($scope.columns, field: field).sort e
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
        when 9 #tab
          $scope.toggleFocusedPane()
          $scope.safeApply()
          false
        when 38 #up arrow
          if $scope.data.focusedPane is 'grid'
            selectAdjacentTrack e, -1
            $scope.safeApply()
          else
            $scope.selectAdjacentListItem -1
            $scope.safeApply()
          false
        when 40 #down arrow
          if $scope.data.focusedPane is 'grid'
            selectAdjacentTrack e, 1
            $scope.safeApply()
          else
            $scope.selectAdjacentListItem 1
            $scope.safeApply()
          false
]
