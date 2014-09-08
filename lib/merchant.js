var Merchant, Promise, debug, errors, request, url, _;

url = require('url');

_ = require('lodash');

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

  Merchant.prototype.format = function(json) {
    var ShippingDetail;
    if (_.isArray(json)) {
      return json.map((function(_this) {
        return function(item) {
          return _this.format(item);
        };
      })(this));
    }
    if (json.Product) {
      json = json.Product;
      if (json.is_promoted) {
        json.is_promoted = json.is_promoted === 'True';
      }
      ['number_saves', 'number_sold'].map(function(key) {
        if (json[key]) {
          return json[key] = Number(json[key]);
        }
      });
    }
    if (json.Variant) {
      json = json.Variant;
      if (json.enabled) {
        json.enabled = json.enabled === 'True';
      }
      ['msrp', 'inventory', 'price', 'shipping'].map(function(key) {
        if (json[key]) {
          return json[key] = Number(json[key]);
        }
      });
    }
    if (json.Order) {
      json = json.Order;
      if (ShippingDetail = json.ShippingDetail, json) {
        _.assign(json, ShippingDetail);
        delete json.ShippingDetail;
      }
      ['order_total', 'quantity', 'price', 'cost', 'shipping', 'shipping_cost', 'days_to_fulfill'].map(function(key) {
        if (json[key]) {
          return json[key] = Number(json[key]);
        }
      });
      ['last_updated', 'order_time'].map(function(key) {
        if (json[key]) {
          return json[key] = new Date(json[key]);
        }
      });
    }
    json = json.Tag || json;
    if (json.tags) {
      json.tags = this.format(json.tags);
    }
    if (json.auto_tags) {
      json.auto_tags = this.format(json.auto_tags);
    }
    if (json.variants) {
      json.variants = this.format(json.variants);
    }
    return json;
  };

  Merchant.prototype.url = function(path, query) {
    var uri;
    uri = url.parse(this.baseUrl);
    uri.pathname += path;
    uri.path = '';
    if (uri.query == null) {
      uri.query = {};
    }
    _.assign(uri.query, query, {
      key: this.key
    });
    return url.format(uri);
  };

  Merchant.prototype.handle = function(promise) {
    return promise["catch"](function(_arg) {
      var body, res;
      res = _arg[0], body = _arg[1];
      debug('HTTP Status', res.statusCode);
      throw errors.http(res.statusCode);
    }).then(function(_arg) {
      var body, code, res;
      res = _arg[0], body = _arg[1];
      debug(body.code, body.message);
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

  Merchant.prototype.get = function(path, query) {
    var uri;
    if (query == null) {
      query = {};
    }
    if (!this.key) {
      return Promise.reject(new errors.ParamError);
    }
    uri = this.url(path, query);
    debug('GET', uri);
    return this.handle(request.getAsync(uri, {
      json: true,
      timeout: this.timeout
    }));
  };

  Merchant.prototype.post = function(path, form) {
    var uri;
    if (!this.key) {
      return Promise.reject(new errors.ParamError);
    }
    uri = this.url(path);
    form.key = this.key;
    debug('POST', uri, form);
    return this.handle(request.postAsync(url, {
      json: true,
      timeout: this.timeout,
      form: form
    }));
  };

  Merchant.prototype.authTestJSON = function(callback) {
    return this.get('/auth_test').nodeify(callback);
  };

  Merchant.prototype.authTest = function(callback) {
    return this.authTestJSON().then((function(_this) {
      return function(json) {
        return _this.format(json.data);
      };
    })(this)).nodeify(callback);
  };

  Merchant.prototype.productJSON = function(id, callback) {
    return this.get('/product', {
      id: id
    }).nodeify(callback);
  };

  Merchant.prototype.product = function(id, callback) {
    return this.productJSON(id).then((function(_this) {
      return function(json) {
        return _this.format(json.data);
      };
    })(this)).nodeify(callback);
  };

  Merchant.prototype.productsJSON = function(start, limit, callback) {
    if (start == null) {
      start = 0;
    }
    if (limit == null) {
      limit = 50;
    }
    return this.get('/product/multi-get', {
      start: start,
      limit: limit
    }).nodeify(callback);
  };

  Merchant.prototype.products = function(start, limit, callback) {
    return this.productsJSON(start, limit).then((function(_this) {
      return function(json) {
        return _this.format(json.data);
      };
    })(this)).nodeify(callback);
  };

  Merchant.prototype.variantJSON = function(sku, callback) {
    return this.get('/variant', {
      sku: sku
    }).nodeify(callback);
  };

  Merchant.prototype.variant = function(sku, callback) {
    return this.variantJSON(sku).then((function(_this) {
      return function(json) {
        return _this.format(json.data);
      };
    })(this)).nodeify(callback);
  };

  Merchant.prototype.variantsJSON = function(start, limit, callback) {
    if (start == null) {
      start = 0;
    }
    if (limit == null) {
      limit = 50;
    }
    return this.get('/variant/multi-get', {
      start: start,
      limit: limit
    }).nodeify(callback);
  };

  Merchant.prototype.variants = function(start, limit, callback) {
    return this.variantsJSON(start, limit).then((function(_this) {
      return function(json) {
        return _this.format(json.data);
      };
    })(this)).nodeify(callback);
  };

  Merchant.prototype.orderJSON = function(id, callback) {
    return this.get('/order', {
      id: id
    }).nodeify(callback);
  };

  Merchant.prototype.order = function(id, callback) {
    return this.orderJSON(id).then((function(_this) {
      return function(json) {
        return _this.format(json.data);
      };
    })(this)).nodeify(callback);
  };

  return Merchant;

})();
