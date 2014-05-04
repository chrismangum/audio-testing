var gulp = require('gulp'),
  coffee = require('gulp-coffee'),
  uglify = require('gulp-uglify'),
  concat = require('gulp-concat'),
  compass = require('gulp-compass'),
  nodemon = require('gulp-nodemon'),
  jade = require('gulp-jade');

var paths = {
  js: 'public/js/*.coffee',
  jade: 'views/*.jade',
  scss: 'public/css/scss/*.scss'
};

gulp.task('scripts', function () {
  gulp.src(paths.js)
    .pipe(coffee())
    //.pipe(uglify())
    .pipe(concat('app.min.js'))
    .pipe(gulp.dest('public/js'));
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
  gulp.watch(paths.js, ['scripts']);
  gulp.watch(paths.jade, ['jade']);
  gulp.watch(paths.scss, ['compass']);
});

gulp.task('default', ['scripts', 'jade', 'compass', 'watch', 'nodemon']);
