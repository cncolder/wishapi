"use strict";
Object.defineProperties(exports, {
  default: {get: function() {
      return $__default;
    }},
  __esModule: {value: true}
});
var $__debug__;
var debug = ($__debug__ = require("debug"), $__debug__ && $__debug__.__esModule && $__debug__ || {default: $__debug__}).default;
var Debug = (function(name) {
  var d = debug(("wishapi:" + name));
  if (process.memoryUsage) {
    d.mem = (function() {
      var $__1 = process.memoryUsage(),
          rss = $__1.rss,
          heapTotal = $__1.heapTotal,
          heapUsed = $__1.heapUsed;
      rss = Math.round(rss * 0.000001);
      heapTotal = Math.round(heapTotal * 0.000001);
      heapUsed = Math.round(heapUsed * 0.000001);
      d(("rss: " + rss + " MB, heap: " + heapUsed + "/" + heapTotal + " MB"));
    });
  }
  return d;
});
var $__default = Debug;
