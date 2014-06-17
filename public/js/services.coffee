
app.factory '$storage', ->
  class Storage
    constructor: ->
      if localStorage.mediaPlayer
        _.assign @, JSON.parse localStorage.mediaPlayer
      else
        _.assign @,
          #defaults
          volume: 100
          albumSort: 'Artist'
          artworkSize: 'large'
        @resetColumnSettings()
    resetColumnSettings: ->
      @columnPrefs =
        visibility:
          trackNumber: true
          title: true
          artist: true
          album: true
          genre: true
          year: true
        widths:
          trackNumber: 30
        artistColumn: 'Artist (Albums A-Z)'
        order: [
          'trackNumber'
          'title'
          'artist'
          'album'
          'genre'
          'year'
        ]
        sortInfo:
          fields: ['artist', 'album', 'trackNumber']
          directions: ['asc', 'asc', 'asc']
      @save()
    save: ->
      localStorage.mediaPlayer = JSON.stringify @
  new Storage
