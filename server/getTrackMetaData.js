#!/usr/bin/env node

var fs = require('fs'),
  async = require('async'),
  path = require('path'),
  _ = require('lodash');

require('../public/js/aurora.js');
require('../public/js/flac.js');
require('../public/js/mp3.js');
require('../public/js/aac.js');

function toBuffer(ab) {
  var buffer = new Buffer(ab.byteLength);
  var view = new Uint8Array(ab);
  for (var i = 0; i < buffer.length; ++i) {
      buffer[i] = view[i];
  }
  return buffer;
}

function processCoverArt(track, data) {
  var folderPath = path.dirname(track) + '/coverArt';
  var filePath = folderPath + '/' + data.artist + ' - ' + data.album + '.jpg'
  if (!fs.existsSync(filePath)) {
    if (!fs.existsSync(folderPath)) {
      fs.mkdirSync(folderPath);
    }
    fs.writeFileSync(filePath, toBuffer(data.coverArt.data.buffer));
  }
  return filePath.slice(2);
}

function processData(track, data, callback) {
  var player = AV.Player.fromBuffer(new Uint8Array(data));
  var coverArtPath;
  player.preload();
  player.on('metadata', function (data) {
    data.trackNumber = data.trackNumber || data.tracknumber;
    data.year = data.year || data.date || data.releaseDate;
    if (data.trackNumber) {
      data.trackNumber = parseInt(data.trackNumber, 10);
    }
    if (data.coverArt) {
      data.coverArtURL = processCoverArt(track, data);
    }
    callback(null, _.pick(data, [
      'title',
      'artist',
      'album',
      'genre',
      'trackNumber',
      'year',
      'coverArtURL'
    ]));
  });
}
var processDataOnce = _.once(processData);

function readEntireFile(track, callback) {
  fs.readFile(track, function (err, data) {
    if (err) throw err;
    processData(track, data, callback);
  });
}

function readStream(track, callback) {
  var stream = fs.createReadStream(track, {start: 0, end: 9999});
  stream.on('data', function (data) {
    processDataOnce(track, data, callback);
  });
}

function getTrackMetaData(track, callback) {
  if (path.extname(track) === '.m4a') {
    readEntireFile(track, callback);
  } else {
    readStream(track, callback);
  }
}

async.map(process.argv.slice(2), getTrackMetaData,
  function (err, result) {
    process.stdout.write(JSON.stringify(result));
  }
);
