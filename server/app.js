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
  res.json({
    target: target,
    files: scanDir.scan(target + '/')
  });
});
app.get('*', function (req, res) {
  res.sendfile(path.join(__dirname, "../public/index.html"));
});

http.createServer(app).listen(3000);

