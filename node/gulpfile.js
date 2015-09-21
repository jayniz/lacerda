var gulp = require('gulp');
var MSONtoJSON = require('gulp-mson-to-json-schema');

gulp.task('schema', function(){
  return gulp.src('./contracts/**/*.mson')
    .pipe(MSONtoJSON())
    .pipe(gulp.dest('./json'));
});
