var fs = require('fs'),
  _ = require('lodash'),
  path = require('path'),
  async = require('async');

require('../public/js/aurora.js');
require('../public/js/flac.js');
require('../public/js/mp3.js');
require('../public/js/aac.js');

var ftypes = {
  '40': 'directory',
  '12': 'symlink',
  '10': 'file'
};
var validExtensions = [
  '.m4a',
  '.flac',
  '.mp3'
];
var items = [];

function getFtype(mode) {
  return ftypes[mode.toString(8).slice(0, 2)];
}

function getTrackMetaData(track, callback) {
  fs.readFile(track.filePath, function (err, data) {
    var player;
    if (err) throw err;
    player = AV.Player.fromBuffer(new Uint8Array(data));
    player.preload();
    player.on('metadata', function () {
      track = _.extend(track,
        _.pick(player.metadata, [
          'title',
          'artist',
          'album',
          'genre'
        ])
      );
      callback(err, track);
    });
  });
}

function hasValidExt(fileName) {
  return validExtensions.indexOf(path.extname(fileName)) !== -1;
}

function getTotalSize(tracks) {
  var totalSize = 0;
  _.each(tracks, function (track) {
    totalSize += track.fileSize;
  });
  return totalSize;
}

function scanDir(filePath) {
  _.each(fs.readdirSync(filePath), function (item, i) {
    var stat = fs.statSync(filePath + item);
    stat.type = getFtype(stat.mode);
    if (stat.type === 'directory') {
      scanDir(filePath + item + '/');
    } else if (hasValidExt(item)) {
      items.push({
        fileName: item,
        filePath: filePath + item,
        fileSize: stat.size
      });
    }
  });
  return items;
}

function getMetaData(tracks, callback) {
  async.map(tracks, getTrackMetaData, callback);
}

exports.scan = scanDir;
exports.getTotalSize = getTotalSize;
exports.getMetaData = getMetaData;
