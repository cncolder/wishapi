{ debug, assert, nock } = require './helpers'
Merchant = require '../src/merchant'
errors = require '../src/errors'


describe 'Merchant', ->
  it 'should run in sandbox when test', ->
    merchant = new Merchant sandbox: true
    assert.equal merchant.baseUrl, 'https://sandbox.merchant.wish.com/api/v1'
    
  describe 'url', ->
    merchant = new Merchant sandbox: true
  
    it 'should append path', ->
      uri = merchant.url '/test'
      assert.equal uri, 'https://sandbox.merchant.wish.com/api/v1/test?key='
    
    it 'should append query', ->
      uri = merchant.url '/test', foo: 'bar'
      assert.equal uri, 'https://sandbox.merchant.wish.com/api/v1/test?foo=bar&key='
  
  describe 'format', ->
    merchant = new Merchant sandbox: true
    
    describe 'tags', ->
      it 'should extract tags', ->
        flat = merchant.format tags: [ Tag: id: 'jimmy' ]
        assert.deepEqual flat, tags: [ id: 'jimmy' ]
    
      it 'should extract auto_tags', ->
        flat = merchant.format auto_tags: [ Tag: id: 'jimmy' ]
        assert.deepEqual flat, auto_tags: [ id: 'jimmy' ]
    
    describe 'product', ->
      it 'should extract Product', ->
        flat = merchant.format Product: id: 1
        assert.deepEqual flat, id: 1
    
      it 'should adjust is_promoted to bool', ->
        flat = merchant.format Product: is_promoted: 'True'
        assert.strictEqual flat.is_promoted, true
        flat = merchant.format Product: is_promoted: 'False'
        assert.strictEqual flat.is_promoted, false
    
      it 'should cast number', ->
        flat = merchant.format Product:
          number_saves: '10'
          number_sold: '2'
        assert.strictEqual flat.number_saves, 10
        assert.strictEqual flat.number_sold, 2
    
    describe 'variants', ->
      it 'should flatten', ->
        flat = merchant.format variants: [ Variant: id: '1' ]
        assert.deepEqual flat, variants: [ id: '1' ]
    
      it 'should extract Variant', ->
        flat = merchant.format Variant: id: 1
        assert.deepEqual flat, id: 1
    
      it 'should adjust enabled to bool', ->
        flat = merchant.format Variant: enabled: 'True'
        assert.strictEqual flat.enabled, true
        flat = merchant.format Variant: enabled: 'False'
        assert.strictEqual flat.enabled, false
    
      it 'should cast price', ->
        flat = merchant.format Variant:
          msrp: '50'
          inventory: '100'
          price: '20'
          shipping: '5'
        assert.strictEqual flat.msrp, 50
        assert.strictEqual flat.inventory, 100
        assert.strictEqual flat.price, 20
        assert.strictEqual flat.shipping, 5
    
    describe 'order', ->
      it 'should extract Order', ->
        flat = merchant.format Order: id: 1
        assert.deepEqual flat, id: 1
    
      it 'should cast quantity price and shipping', ->
        flat = merchant.format Order:
          order_total: '50'
          quantity: '1'
          price: '100.9'
          cost: '99'
          shipping: '5'
          shipping_cost: '6'
          days_to_fulfill: '7'
        assert.strictEqual flat.order_total, 50
        assert.strictEqual flat.quantity, 1
        assert.strictEqual flat.price, 100.9
        assert.strictEqual flat.cost, 99
        assert.strictEqual flat.shipping, 5
        assert.strictEqual flat.shipping_cost, 6
        assert.strictEqual flat.days_to_fulfill, 7
    
      it 'should cast date', ->
        flat = merchant.format Order:
          last_updated: '2013-12-06T20:20:20'
          order_time: '2013-12-06T20:20:20'
        assert.instanceOf flat.last_updated, Date
        assert.instanceOf flat.order_time, Date
        assert.equal flat.order_time.getUTCHours(), 20
    
    describe 'array', ->
      it 'should flatten', ->
        flat = merchant.format [
          { Product: id: 1 }
          { Product: id: 2 }
        ]
        assert.deepEqual flat, [
          { id: 1 }
          { id: 2 }
        ]
  
  describe 'authTest', ->
    describe 'without key', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/auth_test?key='
          .reply 400,
            {"message":"Required Param 'key' Missing","code":1001,"data":"key"}
            
      it 'should reject ParamError', ->
        merchant = new Merchant sandbox: true
        assert.isRejected merchant.authTest(), errors.ParamError
    
    describe 'wrong key', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/auth_test?key=0'
          .reply 401,
            {"message":"Unauthorized Request","code":4000,"data":{}}
            
      it 'should reject AuthError', ->
        merchant = new Merchant
          sandbox: true
          key: '0'
        assert.isRejected merchant.authTest(), errors.AuthError
    
    describe 'right key', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/auth_test?key=test'
          .reply 200,
            {"message":"","code":0,"data":{"success":true}}
      
      it 'should success', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        assert.becomes merchant.authTest(), success: true
        
  describe 'product', ->
    describe 'wrong id', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/product?id=0&key=test'
          .reply 400,
            {"message":"No 'Product' Found with id: '0'","code":1004,"data":2018}
      
      it 'should reject NotFoundError', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.product '0'
        assert.isRejected promise, errors.NotFoundError
    
    describe 'right id', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/product?id=51e0a2c47d41a236cfffe3a0&key=test'
          .reply 200, {
            "message":"","code":0,
            "data":{
              "Product":{
                "is_promoted":"False",
                "description":"JIMMY CRACK CORN",
                "tags":[
                  {"Tag":{"id":"jimmy","name":"jimmy"}},
                  {"Tag":{"id":"gaming","name":"Gaming"}}
                ],
                "upc":"000000000000",
                "name":"TEST!!!",
                "auto_tags":[
                  {"Tag":{"id":"test","name":"test"}}
                ],
                "number_saves":"12529",
                "variants":[{
                  "Variant":{
                    "sku":"Bottle-1-L",
                    "msrp":"20000.0",
                    "inventory":"100",
                    "price":"10000.0",
                    "enabled":"True",
                    "id":"51e0a2c67d41a236cfffe3a2",
                    "shipping":"101.0",
                    "shipping_time":"7-14"
                  }
                }],
                "parent_sku":"Bottle-1",
                "id":"51e0a2c47d41a236cfffe3a0",
                "number_sold":"14"
              }
            }
          }
      
      it 'should get product', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.product '51e0a2c47d41a236cfffe3a0'
        assert.isFulfilled promise.then (product) ->
          assert.equal product.name, 'TEST!!!'
          assert.strictEqual product.number_saves, 12529
          assert.strictEqual product.number_sold, 14
          assert.strictEqual product.number_sold, 14
          assert.equal product.tags[1].name, 'Gaming'
          assert.equal product.auto_tags[0].id, 'test'
          assert.strictEqual product.variants[0].enabled, true
          assert.strictEqual product.variants[0].msrp, 20000
          assert.strictEqual product.variants[0].inventory, 100
          assert.strictEqual product.variants[0].price, 10000
          assert.strictEqual product.variants[0].shipping, 101
  
  describe 'products', ->
    describe 'first two', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/product/multi-get?start=0&limit=2&key=test'
          .reply 200, {
            "message":"","code":0,
            "data":[
              {"Product":{"parent_sku":"Bottle-1","id":"51e0a2c47d41a236cfffe3a0"}},
              {"Product":{"id":"51e0a2c47d41a236cfffe3a4","parent_sku":"Bottle-2"}}
            ],
            "paging":{"next": "https:\/\/sandbox.merchant.wish.com\/api\/v1\/product\/multi-get?start=2&limit=2&key=test"}
          }
      
      it 'should get multi products', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.products 0, 2
        assert.isFulfilled promise.then (products) ->
          assert.lengthOf products, 2
  
  describe 'variant', ->
    describe 'wrong sku', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/variant?sku=zzz&key=test'
          .reply 400,
            {"message":"No 'Variant' Found with sku: 'zzz'","code":1004,"data":{}}
      
      it 'should reject NotFoundError', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.variant 'zzz'
        assert.isRejected promise, errors.NotFoundError
      
    describe 'large bottle', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/variant?sku=Bottle-1-L&key=test'
          .reply 200,{
            "message":"","code":0,
            "data":{
              "Variant":{
                "sku":"Bottle-1-L",
                "msrp":"20000.0",
                "inventory":"100",
                "price":"10000.0",
                "enabled":"True",
                "id":"51e0a2c67d41a236cfffe3a2",
                "shipping":"101.0",
                "shipping_time":"7-14"
              }
            }
          }
      
      it 'should get variant', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.variant 'Bottle-1-L'
        assert.isFulfilled promise.then (variant) ->
          assert.strictEqual variant.shipping, 101
  
  describe 'variants', ->
    describe 'three', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/variant/multi-get?start=0&limit=3&key=test'
          .reply 200, {
            "message":"","code":0,
            "data":[
              {"Variant":{"sku":"Bottle-1-L"}},
              {"Variant":{"sku":"Bottle-2-L"}},
              {"Variant":{"sku":"Bottle-3-L"}}
            ],
            "paging":{
              "next": "https:\/\/sandbox.merchant.wish.com\/api\/v1\/variant\/multi-get?start=3&limit=3&key=test"
            }
          }
      
      it 'should get multi variants', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.variants 0, 3
        assert.isFulfilled promise.then (variants) ->
          assert.lengthOf variants, 3
  
  describe 'order', ->
    describe 'invalid id', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/order?id=0&key=test'
          .reply 400,
            {"message":"0 is an invalid id","code":1000,"data":2014}
      
      it 'should reject InvalidIdError', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.order '0'
        assert.isRejected promise, errors.InvalidIdError
      
    describe 'wrong id', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/order?id=123456789012345678901234&key=test'
          .reply 400,
            {"message":"No 'Order' Found with id: '123456789012345678901234'","code":1004,"data":2021}
      
      it 'should reject NotFoundError', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.order '123456789012345678901234'
        assert.isRejected promise, errors.NotFoundError
    
    describe 'right id', ->
      before ->
        nock 'https://sandbox.merchant.wish.com'
          .get '/api/v1/order?id=123456789009876543210164&key=test'
          .reply 200, {
            "message":"","code":0,
            "data":{
              "Order":{
                "ShippingDetail": {
                  "city": "North Bay",
                  "country": "US",
                  "name": "Mick Berry",
                  "phone_number": "+1 555-181-7247",
                  "state": "NC",
                  "street_address1": "2126 PO Box 5 Rt 49",
                  "zipcode": "13123"},
                "last_updated": "2013-12-06T20:20:20",
                "order_time": "2013-12-06T20:20:20",
                "order_id": "123456789009876543210164",
                "order_total": "20",
                "product_id": "1113fad43deaf71536cb2c74",
                "quantity": "2",
                "price":"8",
                "cost":"6.8",
                "shipping":"2.35",
                "shipping_cost":"2",
                "product_name":"Dandelion Necklace",
                "product_image_url": "http://d1zog42tnv16ho.cloudfront.net/4fea11fac43bf532f4001419-normal.jpg",
                "days_to_fulfill": "2",
                "sku": "Dandelion Necklace",
                "state": "APPROVED",
                "transaction_id": "11114026a99e980d4e500269",
                "variant_id": "1111fad63deaf71536cb2c76"
              }
            }
          }
      
      it 'should get order', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.order '123456789009876543210164'
        assert.isFulfilled promise.then (order) ->
          assert.equal order.product_name, 'Dandelion Necklace'
