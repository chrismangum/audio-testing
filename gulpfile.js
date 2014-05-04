var gulp = require('gulp'),
  coffee = require('gulp-coffee'),
  uglify = require('gulp-uglify'),
  concat = require('gulp-concat'),
  compass = require('gulp-compass'),
  nodemon = require('gulp-nodemon'),
  jade = require('gulp-jade');
  svgmin = require('gulp-svgmin');
  iconfont = require('gulp-iconfont');
  iconfontCss = require('gulp-iconfont-css');

var paths = {
  js: 'public/js/*.coffee',
  jade: 'views/*.jade',
  scss: 'public/css/scss/*.scss',
  svg: 'public/svg/*.svg'
};

gulp.task('scripts', function () {
  gulp.src(paths.js)
    .pipe(coffee())
    //.pipe(uglify())
    .pipe(concat('app.min.js'))
    .pipe(gulp.dest('public/js'));
});

gulp.task('compass', ['iconfont'], function () {
  return gulp.src(paths.scss)
    .pipe(compass({
      style: 'compressed',
      sass: 'public/css/scss',
      css: 'public/css'
    }));
});

gulp.task('iconfont', function(){
  return gulp.src(['public/fonts/svg/*.svg'])
    .pipe(svgmin())
    .pipe(iconfontCss({
      fontName: 'icon-font',
      path: 'public/fonts/_icon-font.scss',
      targetPath: '../../public/css/scss/_icon-font.scss',
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
  gulp.watch(paths.js, ['scripts']);
  gulp.watch(paths.jade, ['jade']);
  gulp.watch(paths.scss, ['compass']);
  gulp.watch(paths.svg, ['iconfont']);
});

gulp.task('default', ['scripts', 'jade', 'compass', 'watch', 'nodemon']);
