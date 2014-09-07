var traceur = require('traceur');
var path = require('path');


var options = {
  experimental: true
};
traceur.require.makeDefault(function (filename) {
  options.filename = path.relative(process.cwd(), filename);
  return filename.indexOf('node_modules') === -1;
}, options);


module.exports = traceur;