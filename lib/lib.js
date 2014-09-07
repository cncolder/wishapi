"use strict";
Object.defineProperties(exports, {
  Promise: {get: function() {
      return Promise;
    }},
  request: {get: function() {
      return request;
    }},
  Debug: {get: function() {
      return Debug;
    }},
  __esModule: {value: true}
});
var $__bluebird__,
    $__request__,
    $__debug__;
var Promise = ($__bluebird__ = require("bluebird"), $__bluebird__ && $__bluebird__.__esModule && $__bluebird__ || {default: $__bluebird__}).default;
var Request = ($__request__ = require("request"), $__request__ && $__request__.__esModule && $__request__ || {default: $__request__}).default;
var debug = ($__debug__ = require("debug"), $__debug__ && $__debug__.__esModule && $__debug__ || {default: $__debug__}).default;
var request = bluebird.promisifyAll(Request);
var Debug = (function(name) {
  var d = debug(("wishapi:" + name));
  if (process.memoryUsage) {
    d.mem = (function() {
      var $__3 = process.memoryUsage(),
          rss = $__3.rss,
          heapTotal = $__3.heapTotal,
          heapUsed = $__3.heapUsed;
      rss = Math.round(rss * 0.000001);
      heapTotal = Math.round(heapTotal * 0.000001);
      heapUsed = Math.round(heapUsed * 0.000001);
      d(("rss: " + rss + " MB, heap: " + heapUsed + "/" + heapTotal + " MB"));
    });
  }
  return d;
});
;
