#!/usr/bin/env node

var fs = require('fs'),
  async = require('async'),
  _ = require('lodash');

require('../public/js/aurora.js');
require('../public/js/flac.js');
require('../public/js/mp3.js');
require('../public/js/aac.js');

function getTrackMetaData(track, callback) {
  fs.readFile(track, function (err, data) {
    if (err) throw err;
    var player = AV.Player.fromBuffer(new Uint8Array(data));
    player.preload();
    player.on('metadata', function (data) {
      callback(err, _.pick(data, [
        'title',
        'artist',
        'album',
        'genre'
      ]));
    });
  });
}

async.map(process.argv.slice(2), getTrackMetaData, function (err, result) {
  process.stdout.write(JSON.stringify(result));
});
