var express = require('express'),
  http = require('http'),
  path = require('path'),
  app = express();

app.use(express.logger('dev'));
app.use('/static', express.static(path.join(__dirname, '../public')));
app.get('*', function (req, res) {
  res.sendfile(path.join(__dirname, "../public/index.html"));
});

http.createServer(app).listen(3000);
