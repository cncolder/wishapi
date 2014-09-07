import gutil   from 'gulp-util';
import through from 'gulp/node_modules/vinyl-fs/node_modules/through2';
import traceur from 'traceur';


let gulpTraceur = () => {
  return through.obj( (file, enc, cb) => {
    if (file.isNull()) {
      cb(null, file);
    }
    else if (file.isStream()) {
      cb(new gutil.PluginError('gulp-traceur', 'Streaming not supported'));
    }
    else {
      try {
        let { js, sourceMap } = traceur.moduleToCommonJS(file.contents.toString(), {
          experimental: true,
          filename:     file.relative
        });

        if (js) {
          file.contents = new Buffer(js);
          cb(null, file);
        }
      } catch (err) {
        gutil.log('gulp-traceur', '\n', gutil.colors.red(err.join('\n ')));
      }
    }
  });
};


export default gulpTraceur;