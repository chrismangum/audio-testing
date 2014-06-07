fs = require 'fs'
async = require 'async'
path = require 'path'
_ = require 'lodash'

AV = require '../public/js/nodeAurora.js'
AV.require.apply null, [
  './flac.js'
  './mp3.js'
  './aac.js'
]

toBuffer = (ab) ->
  buffer = new Buffer ab.byteLength
  view = new Uint8Array ab
  for val, i in buffer
    buffer[i] = view[i]
  buffer

processCoverArt = (track, data) ->
  folderPath = path.dirname(track) + '/coverArt'
  filePath = folderPath + '/' + data.artist + ' - ' + data.album + '.jpg'
  unless fs.existsSync filePath
    unless fs.existsSync folderPath
      fs.mkdirSync folderPath
    fs.writeFileSync filePath, toBuffer data.coverArt
  filePath.slice 2

stripOutNullChars = (data) ->
  _.each data, (val, key) ->
    if _.isString val
      data[key] = val.replace /\u0000/g, ''

processData = (track, data, callback) ->
  player = AV.Player.fromBuffer data
  player.preload()
  player.on 'metadata', (data) ->
    stripOutNullChars data
    data.trackNumber = data.trackNumber or data.tracknumber
    data.year = data.year or data.date or data.releaseDate
    data.coverArt = data.coverArt?.data.buffer or data.PIC?.data.data.buffer
    if data.year
      data.year = parseInt data.year, 10
    if data.trackNumber
      data.trackNumber = parseInt data.trackNumber, 10
    if data.coverArt
      data.coverArtURL = processCoverArt track, data
    callback null, _.pick data, [
      'title'
      'artist'
      'album'
      'genre'
      'trackNumber'
      'year'
      'coverArtURL'
    ]

getTrackMetaData = (track, callback) ->
  fileData = null
  stream = fs.createReadStream track,
    #read first 500KB of file
    start: 0, end: 511999
  stream.on 'data', (data) ->
    unless fileData
      fileData = data
    else
      fileData = Buffer.concat [fileData, data]
  stream.on 'end', ->
    processData track, fileData, callback

async.map process.argv.slice(2), getTrackMetaData,
  (err, result) ->
    process.stdout.write JSON.stringify result
