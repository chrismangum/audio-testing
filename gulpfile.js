var gulp = require('gulp'),
    plugin = require('gulp-load-plugins')({camelize:true}),
    wiredep = require('wiredep').stream;

var paths = {
  clientJS: 'public/js/**/*.coffee',
  serverJS: 'server/*.coffee',
  jade: 'views/*.jade',
  scss: ['public/css/**/*.scss', '!public/css/_icon-font.scss'],
  svg: 'public/svg/*.svg'
};

gulp.task('clientJS', function () {
  gulp.src(paths.clientJS)
    .pipe(plugin.coffee())
    //.pipe(plugin.uglify())
    .pipe(gulp.dest('public/js/compiled'));
});

gulp.task('serverJS', function () {
  gulp.src(paths.serverJS)
    .pipe(plugin.coffee())
    //.pipe(plugin.concat('app.js'))
    .pipe(gulp.dest('server'));
});

gulp.task('css', ['iconfont'], function () {
  return gulp.src(paths.scss)
    .pipe(plugin.sass())
    .pipe(plugin.autoprefixer("last 2 versions"))
    .pipe(plugin.minifyCss())
    .pipe(gulp.dest('public/css'))
});

gulp.task('iconfont', function(){
  return gulp.src(['public/fonts/svg/*.svg'])
    .pipe(plugin.svgmin())
    .pipe(plugin.iconfontCss({
      fontName: 'icon-font',
      path: 'public/fonts/_icon-font.scss',
      targetPath: '../../public/css/_icon-font.scss',
      fontPath: '../../../fonts/'
    }))
    .pipe(plugin.iconfont({
      fontName: 'icon-font',
      normalize: true
    }))
    .pipe(gulp.dest('public/fonts/'))
});

gulp.task('jade', function () {
  gulp.src(paths.jade)
    .pipe(plugin.jade({
      pretty: true
    }))
    .pipe(gulp.dest('public/'));
});

gulp.task('wiredep', function () {
  gulp.src('./public/index.html')
    .pipe(wiredep({
      fileTypes: {
        html: {
          replace: {
            js: '<script src="/static/{{filePath}}"></script>'
          }
        }
      }
    }))
    .pipe(gulp.dest('./public'));
});

gulp.task('nodemon', function () {
  plugin.nodemon({
    script: 'server/app.js',
    ext: 'js',
    ignore: ['public/*', 'node_modules/*']
  });
});

gulp.task('watch', function () {
  gulp.watch(paths.clientJS, ['clientJS']);
  gulp.watch(paths.serverJS, ['serverJS']);
  gulp.watch(paths.jade, ['views']);
  gulp.watch(paths.scss, ['css']);
  gulp.watch(paths.svg, ['css']);
});

gulp.task('views', ['jade', 'wiredep']);
gulp.task('default', ['clientJS', 'serverJS', 'views', 'css', 'watch', 'nodemon']);
