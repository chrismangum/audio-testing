var fs = require('fs'),
  _ = require('lodash'),
  path = require('path'),
  async = require('async'),
  exec = require('child_process').exec;

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

function getFtype(mode) {
  return ftypes[mode.toString(8).slice(0, 2)];
}

function getTrackMetaData(track, callback) {
  exec('./getTrackMetaData.js "' + track.filePath + '"',
    function (err, stdout, stderr) {
      callback(err, _.extend(track, JSON.parse(stdout)[0]));
    }
  );
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
  var items = [];
  _.each(fs.readdirSync(filePath), function (item) {
    var stat = fs.statSync(filePath + item);
    stat.type = getFtype(stat.mode);
    if (stat.type === 'directory') {
      items = items.concat(scanDir(filePath + item + '/'));
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
  async.mapSeries(tracks, getTrackMetaData, callback);
}

exports.scan = scanDir;
exports.getTotalSize = getTotalSize;
exports.getMetaData = getMetaData;
