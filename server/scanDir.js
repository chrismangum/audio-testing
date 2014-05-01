var fs = require('fs'),
  _ = require('lodash'),
  path = require('path');

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

var ignored = ['node_modules', 'vendor', '.git'];

function getFtype(mode) {
  return ftypes[mode.toString(8).slice(0, 2)];
}

function logMetaData(path) {
  fs.readFile(path, function (err, data) {
    var player;
    if (err) throw err;
    player = AV.Player.fromBuffer(new Uint8Array(data));
    player.preload();
    player.on('metadata', function (data) {
      console.log('Metadata for: ' + path);
      console.log(_.pick(data, ['title', 'artist', 'album', 'genre']));
    });
  });
}

function hasValidExt(fileName) {
  return validExtensions.indexOf(path.extname(fileName)) !== -1;
}

function scanDir(filePath) {
  var items = {};
  _.each(fs.readdirSync(filePath), function (item, i) {
    if (ignored.indexOf(item) === -1) {
      var stat = fs.statSync(filePath + item);
      stat.type = getFtype(stat.mode);
      if (stat.type === 'directory') {
        stat.children = scanDir(filePath + item + '/');
      } else if (hasValidExt(item)) {
        logMetaData(filePath + item);
      }
      items[item] = _.pick(stat, 'type', 'children');
    }
  });
  return items;
}

exports.scan = scanDir;

