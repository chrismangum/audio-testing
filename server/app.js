var express = require('express'),
  http = require('http'),
  path = require('path'),
  fs = require('fs'),
  scanDir = require('./scanDir'),
  app = express();

var target;
process.chdir(path.join(__dirname, '../target'));
target = process.cwd();
process.chdir(__dirname);

app.use(express.logger('dev'));
app.set('json spaces', 0);
app.use('/static', express.static(path.join(__dirname, '../public')));
app.use('/target', express.static(target));
app.get('/dir', function (req, res) {
  var tracks = scanDir.scan(target + '/');
  var totalSize = scanDir.getTotalSize(tracks);
  //scanDir.getMetaData(tracks, function (err, tracks) {
    res.json({
      tracks: tracks,
      totalSize: totalSize,
      totalCnt: Object.keys(tracks).length
    });
  //});
});
app.get('*', function (req, res) {
  res.sendfile(path.join(__dirname, "../public/index.html"));
});

http.createServer(app).listen(3000);

