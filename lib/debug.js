var debug;

debug = require('debug');

module.exports = function(name) {
  var d, mb;
  d = debug("wishapi:" + name);
  if (process.memoryUsage) {
    mb = function(n) {
      return Math.round(n * 0.000001);
    };
    d.mem = function() {
      var heapTotal, heapUsed, rss, _ref;
      _ref = process.memoryUsage(), rss = _ref.rss, heapTotal = _ref.heapTotal, heapUsed = _ref.heapUsed;
      return debug("rss: " + (mb(rss)) + " MB, heap: " + (mb(heapUsed)) + "/" + (mb(heapTotal)) + " MB");
    };
  }
  return d;
};
