#!/usr/bin/env node

var fs = require('fs'),
  async = require('async'),
  _ = require('lodash');

require('../public/js/aurora.js');
require('../public/js/flac.js');
require('../public/js/mp3.js');
require('../public/js/aac.js');

function processData(data, callback) {
    var player = AV.Player.fromBuffer(new Uint8Array(data));
    player.preload();
    player.on('metadata', function (data) {
      callback(null, _.pick(data, [
        'title',
        'artist',
        'album',
        'genre'
      ]));
    });
}
var processDataOnce = _.once(processData);

function getTrackMetaData(track, callback) {
  var stream = fs.createReadStream(track, {start: 0, end: 9999});
  stream.on('data', function (data) {
    processDataOnce(data, callback);
  });
}

async.map(process.argv.slice(2), getTrackMetaData,
  function (err, result) {
    process.stdout.write(JSON.stringify(result));
  }
);
