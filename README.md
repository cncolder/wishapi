[![Build Status][travis-img]][travis-url] [![Coverage Status][coveralls-img]][coveralls-url] [![NPM version][npm-img]][npm-url] [![Greenkeeper badge][greenkeeper-img]][greenkeeper-url]

wishapi
=======

Wish.com api for Node.js.

Install
-------

```bash
npm install wishapi
```

Use
---

```javascript
var wishapi = require('wishapi');
var merchant = new wishapi.Merchant({
  key: 'your merchant api key'
});

merchant.authTest()
  .then(function(success) {
    console.log(success)
  });

merchant.product('a product id')
  .then(function(product) {
    // a plain javascript object.
  })
  .catch(function(err) {
    // something wrong.
    // the err has details and error code.
  });
```

Don't favor promise?
--------------------

Thanks [Bluebird][bluebird]. We provide callback too.

```javascript
merchant.fulfillOrder({
  id: 'order id',
  tracking_provider: 'USPS',
  tracking_number: '12345678'
}, (err, success) {
  if (err) {
    console.error(err);
  } else if (success) {
    // ...
  }
});
```

Document
--------

First, you need read [Official api document][official-doc]. To understand every model property.

About Merchant class you can read [an annotated source][merchant-doc]. It write by coffee script. But you don't need install it. The code you installed by npm is compiled vanilla javascript.

This api return some wish special error type. You can find them at [errors annotated source][errors-doc].

Issue
-----

Our code have pass [100% test converage][coverage] currently.

If you find out any issues. Please [let me know][issues].

If you have any good idea. Send me a pull request.


[travis-url]: https://travis-ci.org/cncolder/wishapi
[travis-img]: https://travis-ci.org/cncolder/wishapi.svg?branch=master

[coveralls-url]: https://coveralls.io/r/cncolder/wishapi?branch=master
[coveralls-img]: https://coveralls.io/repos/cncolder/wishapi/badge.png?branch=master

[npm-url]: https://npmjs.org/package/wishapi
[npm-img]: https://img.shields.io/npm/v/wishapi.svg

[greenkeeper-url]: https://greenkeeper.io/
[greenkeeper-img]: https://badges.greenkeeper.io/cncolder/wishapi.svg

[bluebird]: https://github.com/petkaantonov/bluebird
[official-doc]: https://merchant.wish.com/documentation/api
[merchant-doc]: https://cncolder.github.io/wishapi/docs/merchant.html
[errors-doc]: https://cncolder.github.io/wishapi/docs/errors.html
[coverage]: https://cncolder.github.io/wishapi/docs/coverage.html

[issues]: https://github.com/cncolder/wishapi/issues
