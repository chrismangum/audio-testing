var express = require('express'),
  http = require('http'),
  path = require('path'),
  fs = require('fs'),
  scanDir = require('./scanDir'),
  _ = require('lodash'),
  app = express(),
  async = require('async'),
  exec = require('child_process').exec,
  server = require('http').createServer(app),
  io = require('socket.io').listen(server);

server.listen(3000);
process.chdir(__dirname);

app.use(express.logger('dev'));
app.set('json spaces', 0);
app.use('/static', express.static(path.join(__dirname, '../public')));
app.get('/dir', function (req, res) {
});
app.get('/', function (req, res) {
  res.sendfile(path.join(__dirname, "../public/index.html"));
});

var target, json, socket, scanned = true;;

function useTarget(target) {
  app.use('/target', express.static(target));
  /*app.get('*', function (req, res) {
    res.sendfile(path.join(__dirname, "../public/index.html"));
  });*/
}

function checkTarget() {
  var target = false;
  if (fs.existsSync('../target')) {
    process.chdir(path.join(__dirname, '../target'));
    target = process.cwd();
    useTarget(target);
    process.chdir(__dirname);
  }
  return target;
}

function createTarget(target) {
  fs.symlinkSync('../target', target);
  useTarget(target);
}

function scanTarget(target) {
  var tracks = scanDir.scan(target + '/');
  var totalSize = scanDir.getTotalSize(tracks);
  var trackObj = {};
  _.each(tracks, function (track) {
    trackObj[track.filePath] = _.omit(track, 'filePath');
  });
  json = {
    tracks: trackObj,
    totalSize: totalSize,
    totalCnt: Object.keys(tracks).length
  };
  saveJSON(json);
  socket.emit('json', json);
  scanMetaData(json, socket);
}

function checkJSON() {
  var json = false;
  if (fs.existsSync('../cache.json')) {
    json = JSON.parse(fs.readFileSync('../cache.json').toString());
  }
  return json;
}

function saveJSON(json) {
  fs.writeFileSync('../cache.json', JSON.stringify(json));
}

function scanMetaData(json) {
  async.eachSeries(_.keys(json.tracks), getTrackMetaData, function (err) {
    if (!err) {
      console.log('metadata scan complete. saving json...');
      scanned = true;
      saveJSON(json);
    } else {
      console.log('scan interrupted. saving json...');
      saveJSON(json);
    }
  });
}

function getTrackMetaData(track, callback) {
  if (!socket) {
    callback(true);
  } else if (json.tracks[track].scanned) {
    callback();
  } else {
    exec('./getTrackMetaData.js "' + track + '"',
      function (err, stdout, stderr) {
        extendTrackInfo(track, JSON.parse(stdout)[0]);
        callback(err);
      }
    );
  }
}

function extendTrackInfo(track, obj) {
  _.extend(json.tracks[track], obj);
  json.tracks[track].scanned = true;
  socket.emit('metadata', json.tracks[track]);
}

io.sockets.on('connection', function (sckt) {
  socket = sckt;
  if (typeof target === 'undefined') {
    target = checkTarget();
  }

  if (!target) {
    socket.emit('promptTarget');
  } else {
    if (typeof json === 'undefined') {
      json = checkJSON();
    }
    if (json) {
      socket.emit('json', json);
      if (!scanned) {
        scanMetaData(json, socket);
      }
    } else {
      scanTarget(target);
    }
  }

  socket.on('target', function (path) {
    target = path;
    createTarget(target);
    scanTarget(target);
  });

  socket.on('disconnect', function () {
    socket = false;
  });
});