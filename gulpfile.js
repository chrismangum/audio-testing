var gulp = require('gulp'),
  coffee = require('gulp-coffee'),
  uglify = require('gulp-uglify'),
  concat = require('gulp-concat'),
  nodemon = require('gulp-nodemon'),
  jade = require('gulp-jade'),
  sass = require('gulp-sass'),
  prefix = require('gulp-autoprefixer'),
  minifyCss = require('gulp-minify-css'),
  svgmin = require('gulp-svgmin'),
  iconfont = require('gulp-iconfont'),
  iconfontCss = require('gulp-iconfont-css');

var paths = {
  clientJS: 'public/js/*.coffee',
  serverJS: 'server/*.coffee',
  jade: 'views/*.jade',
  scss: ['public/css/*.scss', '!public/css/_icon-font.scss'],
  svg: 'public/svg/*.svg'
};

gulp.task('clientJS', function () {
  gulp.src(paths.clientJS)
    .pipe(coffee())
    //.pipe(uglify())
    .pipe(concat('app.min.js'))
    .pipe(gulp.dest('public/js'));
});

gulp.task('serverJS', function () {
  gulp.src(paths.serverJS)
    .pipe(coffee())
    .pipe(concat('app.js'))
    .pipe(gulp.dest('server'));
});

gulp.task('css', ['iconfont'], function () {
  return gulp.src(paths.scss)
    .pipe(sass())
    .pipe(prefix("last 2 versions"))
    .pipe(minifyCss())
    .pipe(gulp.dest('public/css'))
});

gulp.task('iconfont', function(){
  return gulp.src(['public/fonts/svg/*.svg'])
    .pipe(svgmin())
    .pipe(iconfontCss({
      fontName: 'icon-font',
      path: 'public/fonts/_icon-font.scss',
      targetPath: '../../public/css/_icon-font.scss',
      fontPath: '../fonts/'
    }))
    .pipe(iconfont({
      fontName: 'icon-font',
      normalize: true
    }))
    .pipe(gulp.dest('public/fonts/'))
});

gulp.task('jade', function () {
  gulp.src(paths.jade)
    .pipe(jade())
    .pipe(gulp.dest('public/'));
});

gulp.task('nodemon', function () {
  nodemon({
    script: 'server/app.js',
    ext: 'js,coffee',
    ignore: ['public/**', 'node_modules/**']
  });
});

gulp.task('watch', function () {
  gulp.watch(paths.clientJS, ['clientJS']);
  gulp.watch(paths.serverJS, ['serverJS']);
  gulp.watch(paths.jade, ['jade']);
  gulp.watch(paths.scss, ['css']);
  gulp.watch(paths.svg, ['css']);
});

gulp.task('default', ['clientJS', 'serverJS', 'jade', 'css', 'watch', 'nodemon']);
