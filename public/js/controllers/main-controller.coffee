
app.controller 'main', ['$scope', '$routeParams', '$timeout', '$filter', '$modal', '$q', '$storage'
  ($scope, $routeParams, $timeout, $filter, $modal, $q, $storage) ->
    $scope.params = $routeParams
    $scope.selectedItems = {}
    $scope.gridOptions = {}
    $scope.artwork = 'large'
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
          '<div>
            <div class="modal-header">
              <h4 class="modal-title">Jon\'s Fancy Modal</h4>
            </div>
            <div class="modal-body">
              <p>Jon\'s modal... so fancy...</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-sm btn-default" ng-click="$close()">Close</button>
              <button type="button" class="btn btn-sm btn-danger" ng-click="$dismiss()">Cancel</button>
            </div>
          </div>'
        controller: ['$scope', (scope) ->
          modal.result.then ->
            deferred.resolve {}
        ]
      deferred.promise


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

    $scope.$on 'ngGridEventSorted', do ->
      throttle = null
      (e, sortInfo) ->
        if throttle
          $timeout.cancel throttle
        throttle = $timeout (->
        ), 250

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

    createArtist = (track) ->
      artist =
        songs: [track]
        name: track.artist
        coverArtURL: track.coverArtURL or false
        albums: [createAlbum track]
      $scope.data.artists.push artist
      artist

    createAlbum = (track) ->
      album =
        songs: [track]
        name: track.album
        artist: track.artist
        coverArtURL: track.coverArtURL or false
      $scope.data.albums.push album
      album

    createGenre = (track) ->
      genre =
        songs: [track]
        name: track.genre
      $scope.data.genres.push genre
      genre

    checkAlbum = (artist, track) ->
      unless album = _.find artist.albums, {name: track.album}
        artist.albums.push createAlbum track
      else
        album.songs.push track
        unless album.coverArtURL
          album.coverArtURL = track.coverArtURL or false

    checkArtist = (track) ->
      unless artist = _.find $scope.data.artists, {name: track.artist}
        createArtist track
      else
        artist.songs.push track
        checkAlbum artist, track

    checkGenre = (track) ->
      unless genre = _.find $scope.data.genres, {name: track.genre}
        createGenre track
      else
        genre.songs.push track

    getFirstCoverArt = (songs) ->
      coverArtURL = _.find songs, (song) ->
        _.has song, 'coverArtURL'
      if coverArtURL
        coverArtURL.coverArtURL
      else
        false

    parseData = (data) ->
      $scope.data.songs = _.values data.tracks
      $scope.data.artists = _.compact _.map _.groupBy($scope.data.songs, 'artist'), (songs, artistName) ->
        if artistName isnt "undefined"
          songs: songs
          name: artistName
          coverArtURL: getFirstCoverArt songs
          albums: _.map _.groupBy(songs, 'album'), (songs, albumName) ->
            songs: songs
            name: albumName
            artist: artistName
            coverArtURL: getFirstCoverArt songs
      $scope.data.albums = _.flatten _.pluck($scope.data.artists, 'albums')
      $scope.data.genres = _.compact _.map _.groupBy($scope.data.songs, 'genre'), (songs, genreName) ->
        if genreName isnt "undefined"
          name: genreName
          songs: songs

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
