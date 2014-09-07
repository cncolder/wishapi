"use strict";
Object.defineProperties(exports, {
  default: {get: function() {
      return $__default;
    }},
  __esModule: {value: true}
});
var $__bluebird__,
    $__request__,
    $__debug__;
var Promise = ($__bluebird__ = require("bluebird"), $__bluebird__ && $__bluebird__.__esModule && $__bluebird__ || {default: $__bluebird__}).default;
var request = ($__request__ = require("request"), $__request__ && $__request__.__esModule && $__request__ || {default: $__request__}).default;
var Debug = ($__debug__ = require("./debug"), $__debug__ && $__debug__.__esModule && $__debug__ || {default: $__debug__}).default;
var debug = new Debug('merchant');
var Merchant = function Merchant(options) {
  this.options = {
    apiKey: '',
    sandbox: false
  };
  Object.assign(this.options, options);
  if (this.options.sandbox) {
    this.baseUrl = 'https://sandbox.merchant.wish.com/v1';
  } else {
    this.baseUrl = 'https://merchant.wish.com/api/v1';
  }
};
($traceurRuntime.createClass)(Merchant, {authTest: function(callback) {
    request.getAsync('');
  }}, {});
var $__default = Merchant;
