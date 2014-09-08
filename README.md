wishapi [![Build Status](https://secure.travis-ci.org/cncolder/wishapi.png)](http://travis-ci.org/cncolder/wishapi)
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

Thanks [bluebird](https://github.com/petkaantonov/bluebird). We provide callback too.

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

First, you need read [official api document](https://merchant.wish.com/documentation/api). To understand every model property.

About Merchant class you can read [an annotated source](http://cncolder.github.io/wishapi/docs/merchant.html). It write by coffee script. But you don't need install it. The code you installed by npm is compiled vanilla javascript.

This api return some wish special error type. You can find them at [errors annotated source](http://cncolder.github.io/wishapi/docs/errors.html).
