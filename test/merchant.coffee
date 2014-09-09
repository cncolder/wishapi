{ debug, assert, nock } = require './helpers'
fixture = require './fixture'
Merchant = require '../src/merchant'
errors = require '../src/errors'


describe 'Merchant', ->
  { apikey } = fixture.sandbox
  wish = nock 'https://sandbox.merchant.wish.com'
  after ->
    if not wish.isDone()
      pendingMocks = wish.pendingMocks().join '\n  '
      console.error "pending mocks:\n  #{pendingMocks}"
  
  
  it 'should run in sandbox when test', ->
    merchant = new Merchant sandbox: true
    assert.equal merchant.baseUrl, 'https://sandbox.merchant.wish.com/api/v1'
  
  
  describe 'url', ->
    merchant = new Merchant sandbox: true
  
    it 'should append path', ->
      uri = merchant.url '/test'
      assert.equal uri, 'https://sandbox.merchant.wish.com/api/v1/test'
    
    it 'should append query', ->
      uri = merchant.url '/test', foo: 'bar'
      assert.equal uri, 'https://sandbox.merchant.wish.com/api/v1/test?foo=bar'
  
  
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
      
      it 'should extrace ShipingDetail', ->
        flat = merchant.format
          Order:
            ShippingDetail:
              city: 'North Bay'
              country: 'US'
              name: 'Mick Berry'
              phone_number: '+1 555-181-7247'
              state: 'NC'
              street_address1: '2126 PO Box 5 Rt 49'
              zipcode: '13123'
        assert.equal flat.city, 'North Bay'
        assert.equal flat.country, 'US'
        assert.equal flat.name, 'Mick Berry'
        assert.equal flat.phone_number, '+1 555-181-7247'
        assert.equal flat.state, 'NC'
        assert.equal flat.street_address1, '2126 PO Box 5 Rt 49'
        assert.equal flat.zipcode, '13123'
        assert.isUndefined flat.ShippingDetail
    
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
      it 'should reject ParamMissingError', ->
        merchant = new Merchant sandbox: true
        assert.isRejected merchant.authTest(), errors.ParamMissingError
    
    describe 'wrong key', ->
      before ->
        [ status, body ] = fixture.sandbox['auth_test?key=0']
        wish
          .get '/api/v1/auth_test?key=0'
          .reply status, body
            
      it 'should reject AuthError', ->
        merchant = new Merchant
          sandbox: true
          key: '0'
        assert.isRejected merchant.authTest(), errors.AuthError
    
    describe 'right key', ->
      merchant = new Merchant
        sandbox: true
        key: 'test'
        
      before ->
        [ status, body ] = fixture.sandbox['auth_test']
        wish
          .get '/api/v1/auth_test?key=test'
          .times 2
          .reply status, body
      
      it 'should success', ->
        assert.becomes merchant.authTest(), success: true
      
      it 'should call nodeify callback', (done) ->
        merchant.authTest (err, result) ->
          assert.ifError err
          assert.equal result.success, true
          done()
  
  describe 'product', ->
    describe 'get', ->
      describe 'with wrong id', ->
        before ->
          [ status, body ] = fixture.sandbox['product?id=0']
          wish
            .get '/api/v1/product?id=0&key=test'
            .reply status, body
      
        it 'should reject NotFoundError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.product '0'
          assert.isRejected promise, errors.NotFoundError
          
      describe 'with right id', ->
        before ->
          [ status, body ] = fixture.sandbox['product?id=540e1415f570545a0d90f344']
          wish
            .get '/api/v1/product?id=540e1415f570545a0d90f344&key=test'
            .reply status, body
      
        it 'should get product', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.product '540e1415f570545a0d90f344'
          assert.isFulfilled promise.then (product) ->
            assert.equal product.name, 'Test Product'
            assert.equal product.tags[0].name, 'tag1'
            assert.strictEqual product.variants[0].price, 2
            
    describe 'multi get', ->
      describe 'first two', ->
        before ->
          [ status, body ] = fixture.sandbox['product/multi-get']
          wish
            .get '/api/v1/product/multi-get?start=0&limit=2&key=test'
            .reply status, body
      
        it 'should get multi products', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.products 0, 2
          assert.isFulfilled promise.then (products) ->
            assert.lengthOf products, 2
            
    describe 'create', ->
      describe 'missing main image', ->
        before ->
          [ status, body ] = fixture.sandbox['product/add# missing main image']
          wish
            .filteringRequestBody /.*Sextoy.*/, 'Sextoy'
            .post '/api/v1/product/add', 'Sextoy'
            .reply status, body

        it 'should reject ParamInvalidError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.createProduct name: 'Sextoy'
          assert.isRejected promise, errors.ParamInvalidIdError
      
      describe 'cannot get image', ->
        before ->
          [ status, body ] = fixture.sandbox['product/add# cannot get image']
          wish
            .filteringRequestBody /.*example.*/, 'example'
            .post '/api/v1/product/add', 'example'
            .reply status, body

        it 'should reject ParamInvalidError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.createProduct main_image: 'http://www.example.com/1.jpg'
          assert.isRejected promise, errors.ParamInvalidIdError
        
      describe 'valid param', ->
        form =
          name: 'Bottle'
          description: 'A bottle'
          tags: 'bottle, glass'
          sku: 'Bottle-1'
          color: ''
          size: ''
          inventory: 100
          price: 50
          shipping: 5
          msrp: 80
          shipping_time: '7-14'
          main_image: 'https://www.google.com/intl/en_ALL/images/srpr/logo11w.png'
          parent_sku: 'Bottle-1'
          brand: 'Wish'
          landing_page_url: ''
          upc: ''
          extra_images: ''
        
        before ->
          [ status, body ] = fixture.sandbox['product/add']
          wish
            .filteringRequestBody /.*Bottle.*/, 'Bottle'
            .post '/api/v1/product/add', 'Bottle'
            .reply status, body
          
        it 'should return new product', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.createProduct form
          assert.isFulfilled promise.then (product) ->
            assert.equal product.name, 'Bottle'
    
    describe 'update', ->
      describe 'missing id and parent_sku', ->
        before ->
          [ status, body ] = fixture.sandbox['product/update# missing id and parent_sku']
          wish
            .filteringRequestBody /.*key.*/, 'key'
            .post '/api/v1/product/update', 'key'
            .reply status, body

        it 'should reject ParamInvalidError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.updateProduct()
          assert.isRejected promise, errors.ParamInvalidIdError
      
      describe 'invalid id', ->
        before ->
          [ status, body ] = fixture.sandbox['product/update# invalid id']
          wish
            .filteringRequestBody /.*id=0.*/, 'id0'
            .post '/api/v1/product/update', 'id0'
            .reply status, body

        it 'should reject ParamInvalidError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.updateProduct id: '0'
          assert.isRejected promise, errors.ParamInvalidIdError
      
      describe 'no exists id', ->
        before ->
          [ status, body ] = fixture.sandbox['product/update# no exists id']
          wish
            .filteringRequestBody /.*id=123456789012345678901234.*/, 'id1234'
            .post '/api/v1/product/update', 'id1234'
            .reply status, body

        it 'should reject NotFoundError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.updateProduct id: '123456789012345678901234'
          assert.isRejected promise, errors.NotFoundError
      
      describe 'no exists sku', ->
        before ->
          [ status, body ] = fixture.sandbox['product/update# no exists sku']
          wish
            .filteringRequestBody /.*parent_sku=0.*/, 'sku0'
            .post '/api/v1/product/update', 'sku0'
            .reply status, body

        it 'should reject NotFoundError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.updateProduct parent_sku: '0'
          assert.isRejected promise, errors.NotFoundError
      
      describe 'valid param', ->
        before ->
          [ status, body ] = fixture.sandbox['product/update']
          wish
            .filteringRequestBody /.*Bottle.*/, 'Bottle'
            .post '/api/v1/product/update', 'Bottle'
            .reply status, body
          
        it 'should return new product', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.updateProduct
            parent_sku: 'Bottle-1'
            description: 'The best bottle in the world.'
          assert.isFulfilled promise
    
    describe 'enable', ->
      before ->
        [ status, body ] = fixture.sandbox['product/enable']
        wish
          .filteringRequestBody /.*Bottle.*/, 'Bottle'
          .post '/api/v1/product/enable', 'Bottle'
          .reply status, body

      it 'should enabled', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.enableProduct parent_sku: 'Bottle-1'
        assert.isFulfilled promise
    
    describe 'disable', ->
      before ->
        [ status, body ] = fixture.sandbox['product/disable']
        wish
          .filteringRequestBody /.*Bottle.*/, 'Bottle'
          .post '/api/v1/product/disable', 'Bottle'
          .reply status, body

      it 'should disabled', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.disableProduct parent_sku: 'Bottle-1'
        assert.isFulfilled promise
  
  describe 'variant', ->
    describe 'get', ->
      describe 'wrong sku', ->
        before ->
          [ status, body ] = fixture.sandbox['variant?sku=zzz']
          wish
            .get '/api/v1/variant?sku=zzz&key=test'
            .reply status, body
      
        it 'should reject NotFoundError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.variant 'zzz'
          assert.isRejected promise, errors.NotFoundError
      
      describe 'large bottle', ->
        before ->
          [ status, body ] = fixture.sandbox['variant?sku=Bottle-1-L']
          wish
            .get '/api/v1/variant?sku=Bottle-1-L&key=test'
            .reply status, body
      
        it 'should get variant', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.variant 'Bottle-1-L'
          assert.isFulfilled promise.then (variant) ->
            assert.strictEqual variant.shipping, 101
  
    describe 'multi get', ->
      describe 'two', ->
        before ->
          [ status, body ] = fixture.sandbox['variant/multi-get']
          wish
            .get '/api/v1/variant/multi-get?start=0&limit=2&key=test'
            .reply status, body
      
        it 'should get multi variants', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.variants 0, 2
          assert.isFulfilled promise
    
    describe 'create', ->
      form =
        parent_sku: 'Bottle-1'
        sku: 'Bottle-1-L'
        size: 'L'
        price: 100
        main_image: 'https://lh6.ggpht.com/CEMGXC5MmqbXaauaM_qq8-e7rjk9O2zcv3QAa9wWlxVKnQ_pF03_t5rp4wM2B-fTf_nep8oBj4E7JgUJwmHFh_G5MUDqHyz5yx6lEkO4=s660'
      
      before ->
        [ status, body ] = fixture.sandbox['variant/add']
        wish
          .filteringRequestBody /.*Bottle-1-L.*/, 'Bottle1L'
          .post '/api/v1/variant/add', 'Bottle1L'
          .reply status, body
        
      it 'should return new variant', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.createVariant form
        assert.isFulfilled promise
      
      describe 'missing size and color', ->
        before ->
          [ status, body ] = fixture.sandbox['variant/add# missing size and color']
          wish
            .filteringRequestBody /.*Bottle-2.*/, 'Bottle2'
            .post '/api/v1/variant/add', 'Bottle2'
            .reply status, body
        
        it 'should reject ParamInvalidIdError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.createVariant sku: 'Bottle-2'
          assert.isRejected promise, errors.ParamInvalidIdError
      
    describe 'update', ->
      before ->
        [ status, body ] = fixture.sandbox['variant/update']
        wish
          .filteringRequestBody /.*Bottle.*/, 'Bottle'
          .post '/api/v1/variant/update', 'Bottle'
          .reply status, body
        
      it 'should success', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.updateVariant
          sku: 'Bottle-1-L'
          price: 100
        assert.isFulfilled promise
    
    describe 'enable', ->
      before ->
        [ status, body ] = fixture.sandbox['variant/enable']
        wish
          .filteringRequestBody /.*Bottle.*/, 'Bottle'
          .post '/api/v1/variant/enable', 'Bottle'
          .reply status, body

      it 'should enabled', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.enableVariant 'Bottle-1-L'
        assert.isFulfilled promise
    
    describe 'disable', ->
      before ->
        [ status, body ] = fixture.sandbox['variant/disable']
        wish
          .filteringRequestBody /.*Bottle.*/, 'Bottle'
          .post '/api/v1/variant/disable', 'Bottle'
          .reply status, body

      it 'should disabled', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.disableVariant 'Bottle-1-L'
        assert.isFulfilled promise
  
  
  describe 'order', ->
    describe 'get', ->
      describe 'invalid id', ->
        before ->
          [ status, body ] = fixture.sandbox['order?id=0']
          wish
            .get '/api/v1/order?id=0&key=test'
            .reply status, body
      
        it 'should reject InvalidIdError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.order '0'
          assert.isRejected promise, errors.ParamInvalidIdError
      
      describe 'wrong id', ->
        before ->
          [ status, body ] = fixture.sandbox['order?id=123456789012345678901234']
          wish
            .get '/api/v1/order?id=123456789012345678901234&key=test'
            .reply status, body
      
        it 'should reject NotFoundError', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.order '123456789012345678901234'
          assert.isRejected promise, errors.NotFoundError
    
      describe 'right id', ->
        before ->
          [ status, body ] = fixture.sandbox['order?id=123456789009876543210164']
          wish
            .get '/api/v1/order?id=123456789009876543210164&key=test'
            .reply status, body
      
        it 'should get order', ->
          merchant = new Merchant
            sandbox: true
            key: 'test'
          promise = merchant.order '123456789009876543210164'
          assert.isFulfilled promise.then (order) ->
            assert.equal order.product_name, 'Dandelion Necklace'
    
    describe 'multi get', ->
      before ->
        [ status, body ] = fixture.sandbox['order/multi-get']
        wish
          .get '/api/v1/order/multi-get?start=0&limit=2&since=&key=test'
          .reply status, body
    
      it 'should get orders', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.orders 0, 2
        assert.isFulfilled promise.then (orders) ->
          assert.lengthOf orders, 2
    
    describe 'unfullfiled', ->
      before ->
        [ status, body ] = fixture.sandbox['order/get-fulfill']
        wish
          .get '/api/v1/order/get-fulfill?start=0&limit=2&since=&key=test'
          .reply status, body
    
      it 'should get orders', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.unfullfiledOrders 0, 2
        assert.isFulfilled promise
    
    describe 'fulfill', ->
      before ->
        [ status, body ] = fixture.sandbox['order/fulfill-one']
        wish
          .filteringRequestBody /.*USPS.*/, 'USPS'
          .post '/api/v1/order/fulfill-one', 'USPS'
          .reply status, body
    
      it 'should success', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.fulfillOrder
          id: '540e1418f570545a1090f34a'
          tracking_provider: 'USPS'
          tracking_number: '12345678'
        assert.isFulfilled promise.then (res) ->
          assert.equal res.success, true
      
    describe 'refund', ->
      before ->
        [ status, body ] = fixture.sandbox['order/refund']
        wish
          .filteringRequestBody /.*reason_code=0.*/, 'reason0'
          .post '/api/v1/order/refund', 'reason0'
          .reply status, body
    
      it 'should success', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.refundOrder
          id: '540e1418f570545a1090f34c'
          reason_code: '0'
        assert.isFulfilled promise.then (res) ->
          assert.equal res.success, true

    describe 'modify', ->
      before ->
        [ status, body ] = fixture.sandbox['order/modify-tracking']
        wish
          .filteringRequestBody /.*tracking_number=9876543210.*/, 'tracking9'
          .post '/api/v1/order/modify-tracking', 'tracking9'
          .reply status, body
        
      it 'should success', ->
        merchant = new Merchant
          sandbox: true
          key: 'test'
        promise = merchant.modifyOrder
          id: '540e1418f570545a1090f34a'
          tracking_provider: 'USPS'
          tracking_number: '9876543210'
        assert.isFulfilled promise
        