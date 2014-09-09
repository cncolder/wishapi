gulp = require 'gulp'
gutil = require 'gulp-util'
# source  require 'vinyl-source-stream'
cache = require 'gulp-cached'
coffee = require 'gulp-coffee'
mocha = require 'gulp-mocha'
del = require 'del'


gulp.task 'default', [ 'watch' ]
gulp.task 'build', [ 'clean', 'coffee' ]

gulp.task 'watch', ->
  gulp.watch 'src/**/*.coffee', [ 'coffee', 'mocha' ]
  gulp.watch 'test/**/*.coffee', [ 'mocha' ]

gulp.task 'clean', (cb) ->
  del 'lib/**/*.js', cb

gulp.task 'coffee', ->
  gulp.src 'src/**/*.coffee'
    .pipe cache 'coffee'
    .pipe coffee( bare: true ).on 'error', gutil.log
    .pipe gulp.dest 'lib'

gulp.task 'mocha', ->
  gulp
    .src 'test/**/*.coffee'
    # .pipe cache 'mocha'
    .pipe mocha
      reporter: 'min'
      timeout:  '30s'
