var gulp = require('gulp'),
  coffee = require('gulp-coffee'),
  uglify = require('gulp-uglify'),
  concat = require('gulp-concat'),
  compass = require('gulp-compass'),
  nodemon = require('gulp-nodemon'),
  jade = require('gulp-jade');

var paths = {
  clientJS: 'public/js/*.coffee',
  serverJS: 'server/*.coffee',
  jade: 'views/*.jade',
  scss: 'public/css/scss/*.scss'
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

gulp.task('compass', function () {
  return gulp.src(paths.scss)
    .pipe(compass({
      style: 'compressed',
      sass: 'public/css/scss',
      css: 'public/css'
    }));
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
  gulp.watch(paths.scss, ['compass']);
});

gulp.task('default', ['clientJS', 'serverJS', 'jade', 'compass', 'watch', 'nodemon']);
