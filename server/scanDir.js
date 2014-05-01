var fs = require('fs'),
  _ = require('lodash');

var ftypes = {
  '40': 'directory',
  '12': 'symlink',
  '10': 'file'
};

var ignored = ['node_modules', 'vendor', '.git'];

function getFtype(mode) {
  return ftypes[mode.toString(8).slice(0, 2)];
}

function scanDir(path) {
  var items = {};
  _.each(fs.readdirSync(path), function (item) {
    if (ignored.indexOf(item) === -1) {
      var stat = fs.statSync(path + item);
      stat.type = getFtype(stat.mode);
      if (stat.type === 'directory') {
        stat.children = scanDir(path + item + '/');
      }
      items[item] = _.pick(stat, 'type', 'children');
    }
  });
  return items;
}

exports.scan = scanDir;

