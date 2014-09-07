import gulp    from 'gulp';
import gutil   from 'gulp-util';
import source  from 'vinyl-source-stream';
import cache   from 'gulp-cached';
import mocha   from 'gulp-mocha';
import traceur from './gulp-traceur';
import del     from './del';


gulp.task('default', [ 'watch' ]);
gulp.task('build', [ 'clean', 'traceur', 'traceur-runtime' ]);

gulp.task('watch', () => {
  gulp.watch('src/**/*.js', [ 'traceur' ]);
  gulp.watch('test/**/*.js', [ 'mocha' ]);
});

gulp.task('clean', (cb) => {
  del('lib/**/*.js', cb);
});

gulp.task('traceur', () => {
  return gulp.src('src/**/*.js')
    .pipe(traceur())
    .pipe(gulp.dest('lib'));
});

gulp.task('traceur-runtime', () => {
  return gulp.src('node_modules/traceur/bin/traceur-runtime.js')
    .pipe(gulp.dest('lib'));
})

gulp.task('mocha', () => {
  return gulp
    .src('test/**/*.js')
    .pipe(cache('mocha'))
    .pipe(mocha({
      reporter: 'dot'
    }));
});