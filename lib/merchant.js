var Merchant, Promise, debug, errors, request;

Promise = require('bluebird');

request = Promise.promisifyAll(require('request'));

errors = require('./errors');

debug = (require('./debug'))('merchant');

module.exports = Merchant = (function() {
  function Merchant(_arg) {
    this.key = _arg.key, this.sandbox = _arg.sandbox, this.timeout = _arg.timeout;
    if (this.sandbox == null) {
      this.sandbox = false;
    }
    if (this.timeout == null) {
      this.timeout = 20 * 1000;
    }
    this.baseUrl = this.sandbox ? 'https://sandbox.merchant.wish.com/api/v1' : 'https://merchant.wish.com/api/v1';
  }

  Merchant.prototype.handleRequest = function(promise) {
    return promise["catch"](function(_arg) {
      var body, res;
      res = _arg[0], body = _arg[1];
      throw errors.http(res.statusCode);
    }).then(function(_arg) {
      var body, code, res;
      res = _arg[0], body = _arg[1];
      code = body.code;
      if (code === 0) {
        return body;
      } else if (code) {
        throw errors.wish(body);
      } else {
        throw errors.ServerError({
          response: body
        });
      }
    });
  };

  Merchant.prototype.get = function(path) {
    var promise, url;
    if (!this.key) {
      return Promise.reject(new errors.KeyError);
    }
    url = "" + this.baseUrl + path + "?key=" + this.key;
    promise = request.getAsync(url, {
      json: true,
      timeout: this.timeout
    });
    return this.handleRequest(promise);
  };

  Merchant.prototype.post = function(path, form) {
    var promise, url;
    if (!this.key) {
      return Promise.reject(new errors.KeyError);
    }
    url = "" + this.baseUrl + path;
    form.key = this.key;
    promise = request.postAsync(url, {
      json: true,
      timeout: this.timeout,
      form: form
    });
    return this.handleRequest(promise);
  };

  Merchant.prototype.authTest = function(callback) {
    return this.get('/auth_test').nodeify(callback);
  };

  return Merchant;

})();
