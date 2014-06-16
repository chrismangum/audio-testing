
app.controller 'main', ['$scope', '$routeParams', '$timeout', '$filter', '$modal', '$q', '$storage'
  ($scope, $routeParams, $timeout, $filter, $modal, $q, $storage) ->
    $scope.params = $routeParams
    $scope.selectedItems = {}
    $scope.gridOptions = {}
    $scope.data =
      shuffledData: []
      sortedData: []
      songs: []
      artists: []
      albums: []
      genres: []
      nowPlaying: false
      searchFocus: false
      focusedPane: 'list'
      songToSelect: false

    $scope.openModal = ->
      deferred = $q.defer()
      modal = $modal.open
        template:
          '<div class="modal-header">
            <span class="modal-name">Settings</span>
            <button type="button" class="button close" ng-click="$close()"><span class="icon-close"></span></button>
          </div>
          <div class="modal-body">
            <div class="settings">
              <div class="form-group">
                <label for="settings-theme">Theme</label>
                <select id="settings-theme">
                  <option>1</option>
                  <option>2</option>
                  <option>3</option>
                </select>
              </div>
              <div class="form-group">
                <label>Metadata</label>
                <div class="button-group">
                  <button class="button">Rescan Metadata</button>
                  <button class="button">Reset Metadata</button>
                </div>
              </div>
              <div class="form-group">
                <label>Column Settings <small>Reset your column settings back to default.</small></label>
                <button class="button">Reset Column Settings</button>
              </div>
            </div>
          </div>'
        controller: ['$scope', (scope) ->
          modal.result.then ->
            deferred.resolve {}
        ]
      deferred.promise

    #artwork size
    $scope.artworkSize = $storage.artworkSize
    $scope.toggleArtworkSize = ->
      $scope.artworkSize = switch $scope.artworkSize
        when 'large' then 'small'
        else 'large'
      $storage.artworkSize = $scope.artworkSize
      $storage.save()

    $scope.setAlbumSort = (sort, preventSort) ->
      if sort is 'Artist'
        $scope.albumSort =
          name: 'Artist'
          value: ['artist', 'name']
      else if sort is 'Title'
        $scope.albumSort =
          name: 'Title'
          value: 'name'
      unless preventSort
        $storage.albumSort = sort
        $storage.save()
        $scope.sortViewData()

    $scope.setAlbumSort $storage.albumSort, true

    $scope.filterData = (songs) ->
      $scope.gridOptions.gridData = songs

    $scope.unfilterData = ->
      $scope.gridOptions.gridData = $scope.data.songs

    $scope.updatePlaylist = ->
      $scope.data.playlist = switch
        when $scope.data.shuffledData.length
          $scope.data.shuffledData
        when $scope.data.sortedData.length
          $scope.data.sortedData
        else
          $scope.gridOptions.gridData

    $scope.play = (track) ->
      $scope.updatePlaylist()
      $scope.$broadcast 'play', track

    $scope.scrollToTrack = (track) ->
      $scope.$broadcast 'scrollToTrack', track

    $scope.selectListItem = (item) ->
      $scope.data.focusedPane = 'list'
      type = $scope.params.group[0...-1]
      if $scope.selectedItems[type]
        $scope.selectedItems[type].selected = false
      item.selected = true
      $scope.selectedItems[type] = item
      #select first song if songToSelect isn't set
      unless $scope.data.songToSelect
        $scope.data.songToSelect = true
      $scope.filterData item.songs

    $scope.safeApply = (fn) ->
      unless $scope.$$phase
        $scope.$apply fn

    $scope.checkRoute = ->
      if view = $scope.params.group
        type = view[0...-1]
        if $scope.gridOptions.selectedItems.length
          item = $scope.gridOptions.selectedItems[0]
          $scope.data.songToSelect = item
          $scope.selectListItem _.find $scope.data[view],
            name: item[type]
        else if $scope.data[view].length
          $scope.selectListItem $scope.data[view][0]
      else
        $scope.unfilterData()
        if $scope.gridOptions.selectedItems.length
          $scope.data.songToSelect = $scope.gridOptions.selectedItems[0]

    class Artist
      constructor: (@songs) ->
        @name = @songs[0].artist
        @coverArtURL = @songs[0].coverArtURL or false
        if @songs.length > 1
          @albums = _.map _.groupBy(@songs, 'album'), (songs, albumName) ->
            new Album songs
        else
          @albums = [new Album @songs]
        $scope.data.artists.push @

    class Album
      constructor: (@songs) ->
        @name = @songs[0].album
        @artist = @songs[0].artist
        @coverArtURL = @songs[0].coverArtURL or false
        $scope.data.albums.push @

    class Genre
      constructor: (@songs) ->
        @name = @songs[0].genre
        $scope.data.genres.push @

    checkAlbum = (artist, track) ->
      unless album = _.find artist.albums, {name: track.album}
        artist.albums.push new Album [track]
      else
        album.songs.push track

    checkArtist = (track) ->
      unless artist = _.find $scope.data.artists, {name: track.artist}
        new Artist [track]
      else
        artist.songs.push track
        checkAlbum artist, track

    checkGenre = (track) ->
      unless genre = _.find $scope.data.genres, {name: track.genre}
        new Genre [track]
      else
        genre.songs.push track

    parseData = (data) ->
      $scope.data.songs = _.values data.tracks
      _.each _.groupBy($scope.data.songs, 'artist'), (songs, artistName) ->
        if artistName isnt "undefined"
          new Artist songs
      _.each _.groupBy($scope.data.songs, 'genre'), (songs, genreName) ->
        if genreName isnt "undefined"
          new Genre songs

    $scope.sortViewData = ->
      if $scope.params.group
        unless $scope.params.group is 'albums'
          $scope.data[$scope.params.group] = $filter('orderBy') $scope.data[$scope.params.group], 'name'
        else
          $scope.data.albums = $filter('orderBy') $scope.data.albums, $scope.albumSort.value

    $scope.mainSocket = io.connect location.origin

    $scope.mainSocket.on 'metadata', (data) ->
      track = $scope.data.tracks[data.filePath]
      _.assign track, _.omit data, 'filePath'
      checkArtist track
      checkGenre track
      $scope.sortViewData()
      $scope.safeApply()

    $scope.mainSocket.on 'json', (data) ->
      _.assign $scope.data, data
      parseData data
      $scope.sortViewData()
      $scope.checkRoute()
      $scope.safeApply()
]
