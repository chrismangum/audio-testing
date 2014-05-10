#!/usr/bin/env node

var fs = require('fs'),
  async = require('async'),
  path = require('path'),
  _ = require('lodash');

require('../public/js/aurora.js');
require('../public/js/flac.js');
require('../public/js/mp3.js');
require('../public/js/aac.js');

function processData(data, callback) {
    var player = AV.Player.fromBuffer(new Uint8Array(data));
    player.preload();
    player.on('metadata', function (data) {
      data.trackNumber = data.trackNumber || data.tracknumber;
      if (data.trackNumber) {
        data.trackNumber = parseInt(data.trackNumber, 10);
      }
      callback(null, _.pick(data, [
        'title',
        'artist',
        'album',
        'genre',
        'trackNumber'
      ]));
    });
}
var processDataOnce = _.once(processData);

function readEntireFile(track, callback) {
  fs.readFile(track, function (err, data) {
    if (err) throw err;
    processData(data, callback);
  });
}

function readStream(track, callback) {
  var stream = fs.createReadStream(track, {start: 0, end: 9999});
  stream.on('data', function (data) {
    processDataOnce(data, callback);
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
