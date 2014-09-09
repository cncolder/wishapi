util = require 'util'
url = require 'url'
Promise = require 'bluebird'
request = Promise.promisifyAll require 'request'
errors = require './errors'
debug = (require './debug') 'merchant'


# - - -
# Merchant
# ========
#
# **Merchant** use for invoke [Wish Merchant API](https://merchant.wish.com/documentation/api). For more infomation please visit [The Wish merchant platform](https://merchant.wish.com).
# - - -
module.exports = class Merchant
  
  # New
  # ---
  #
  # **Create a new instance**
  #
  # `new Merchant({ key, [sandbox], [timeout] })`
  #
  # Arguments
  # 1. options (Object)
  #   * key: Api key of wish. Read [official document](https://merchant.wish.com/documentation/api#get-api-key) for more info.
  #   * sandbox: If `true` will invoke sandbox api for test. Default `false`.
  #   * timeout: Milliseconds wait the respond of api. Default 20s `(20 * 1000)`.
  #
  # Return a new instance.
  #
  # Example
  #
  # ```coffee
  # var api = new Merchant({key: 'your api key here'});
  # ```
  # - - -
  constructor: ({ @key, @sandbox, @timeout }) ->
    @sandbox ?= false
    @timeout ?= 20 * 1000

    @baseUrl = if @sandbox
      'https://sandbox.merchant.wish.com/api/v1'
    else
      'https://merchant.wish.com/api/v1'
  
  # Format json result to flatten javascript object.
  #
  # Example
  #
  # <pre>
  # Before
  # { success: <del>'True'</del> }
  # After
  # { success: true }
  # </pre>
  # 
  # <pre>
  # Before
  # {
  #   <del>Product: {</del>
  #     name: 'Fancy toy',
  #     tags: [{
  #       <del>Tag: {</del> id: 'toy', name: 'toy' <del>}</del>
  #     }]
  #     variants: [{
  #       <del>Variant: {</del> price: <del>'10.5'</del>, enable: <del>'True' }</del>
  #     }]
  #   <del>}</del>
  # }
  # After
  # {
  #   name: 'Fancy toy'
  #   tags: [{ id: 'toy', name: 'toy' }]
  #   variants: [{ price: 10.5, enable: true }]
  # }
  # </pre>
  #
  # <pre>
  # Before
  # {
  #   <del>Order: {</del>
  #     <del>ShippingDetail: {</del> country: 'US' <del>}</del>,
  #     order_time: <del>'2013-12-06T20:20:20'</del>
  #   <del>}</del>
  # }
  # After
  # {
  #   country: 'US',
  #   order_time: new Date(...)
  # }
  # </pre>
  # - - -
  format: (json) ->
    if typeof json.success is 'string'
      json.success = json.success is 'True'
      return json
      
    if util.isArray json
      return json.map (item) => @format item
    
    if json.Product
      json = json.Product
      json.is_promoted = json.is_promoted is 'True' if json.is_promoted
      [ 'number_saves', 'number_sold' ].map (key) ->
        json[key] = Number json[key] if json[key]
    
    if json.Variant
      json = json.Variant
      json.enabled = json.enabled is 'True' if json.enabled
      [ 'msrp', 'inventory', 'price', 'shipping' ].map (key) ->
        json[key] = Number json[key] if json[key]
    
    if json.Order
      json = json.Order
      if json.ShippingDetail
        json[key] = value for key, value of json.ShippingDetail
        delete json.ShippingDetail
      [ 'order_total', 'quantity', 'price', 'cost',
        'shipping', 'shipping_cost', 'days_to_fulfill' ].map (key) ->
        json[key] = Number json[key] if json[key]
      [ 'last_updated', 'order_time' ].map (key) ->
        json[key] = new Date json[key] if json[key]
    
    json = json.Tag or json
    
    if json.tags
      json.tags = @format json.tags
    
    if json.auto_tags
      json.auto_tags = @format json.auto_tags
      
    if json.variants
      json.variants = @format json.variants
    
    json
  
  # Append path and query to base url.
  url: (path, query) ->
    uri = url.parse @baseUrl
    uri.pathname += path
    uri.path = ''
    uri.query ?= {}
    uri.query[key] = value for key, value of query
    url.format uri
  
  # Handle request. catch error.
  handle: (promise) ->
    promise
      .catch ([ res, body ]) ->
        debug 'HTTP Status', res?.statusCode
      
        throw errors.http res?.statusCode or 500
      .then ([ res, body ]) ->
        debug body
      
        { code } = body
      
        if code is 0
          body
        else if code
          throw errors.wish body
        else
          throw errors.ServerError response: body
  
  # Request GET.
  get: (path, query = {}) ->
    return Promise.reject new errors.ParamMissingError if not @key
    
    query.key = @key
    uri = @url path, query
    
    debug 'GET', uri
    
    @handle request.getAsync uri,
      json:    true
      timeout: @timeout
  
  # Request POST
  post: (path, form = {}) ->
    return Promise.reject new errors.ParamMissingError if not @key
    
    uri = @url path
    form.key = @key
    
    debug 'POST', uri, form
    
    @handle request.postAsync uri,
      json:    true
      timeout: @timeout
      form:    form
  
  # Authentication
  # --------------
  #
  # `authTest( [callback] )`
  #
  # Test if api key is valid.
  #
  # return `{success: true}` if success. otherwise error.
  # - - -
  authTest: (callback) ->
    @authTestJSON()
      .then (json) => @format json.data
      .nodeify callback
  
  authTestJSON: (callback) ->
    @get '/auth_test'
      .nodeify callback
  
  # Product
  # -------
  #
  # `product( id, [callback] )`
  #
  # Retrieve the details about a product which exists on the Wish platform.
  #
  # Arguments
  #
  # 1. id (string): The unique wish identifier for this product
  # 2. callback (function): err, result.
  #
  # Return product data.
  # - - -
  product: (id, callback) ->
    @productJSON id
      .then (json) => @format json.data
      .nodeify callback
  
  productJSON: (id, callback) ->
    id = id.id if id.id
    @get '/product', id: id
      .nodeify callback
  
  # `products( [start], [limit], [callback] )`
  # 
  # List all Products
  #
  # Arguments
  #
  # 1. start: *optional* An offset into the list of returned items. Use 0 to start at the beginning. The API will return the requested number of items starting at this offset. Default to 0 if not supplied.
  # 2. limit: *optional* A limit on the number of products that can be returned. Limit can range from 1 to 500 items and the default is 50
  # 3. callback: err, products.
  #
  # Return an products array.
  # - - -
  products: (start, limit, callback) ->
    @productsJSON start, limit
      .then (json) => @format json.data
      .nodeify callback
  
  productsJSON: (start = 0, limit = 50, callback) ->
    @get '/product/multi-get',
      start: start
      limit: limit
    .nodeify callback
  
  # `createProduct( product, [callback] )`
  #
  # Create a Product
  #
  # Arguments
  # 1. product
  #   * name: Name of the product as shown to users on Wish
  #   * description: Description of the product. Should not contain HTML. If you want a new line use "\n".
  #   * tags: Comma separated list of strings that describe the product. Only 10 are allowed. Any tags past 10 will be ignored.
  #   * sku: The unique identifier that your system uses to recognize this product
  #   * color: *optional* The color of the product. Example: red, blue, green
  #   * size: *optional* The size of the product. Example: Large, Medium, Small, 5, 6, 7.5
  #   * inventory: The physical quantities you have for this product
  #   * price: The price of the product when the user purchases one
  #   * shipping: The shipping of the product when the user purchases one
  #   * msrp: *optional* Manufacturer's Suggested Retail Price. This field is recommended as it will show as a strikethrough price on Wish and appears above the selling price for the product.
  #   * shipping_time: *optional* The amount of time it takes for the shipment to reach the buyer. Please also factor in the time it will take to fulfill and ship the item. Provide a time range in number of days. Lower bound cannot be less than 2 days. Example: 15-20
  #   * main_image: URL of a photo of your product. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  #   * parent_sku: *optional* When defining a variant of a product we must know which product to attach the variation to. parent_sku is the unique id of the product that you can use later when using the add product variation API.
  #   * brand: *optional* Brand or manufacturer of your product
  #   * landing_page_url: *optional* URL on your website containing the product details
  #   * upc: *optional* 12-digit Universal Product Codes (UPC)-contains no letters or other characters
  #   * extra_images: *optional* URL of extra photos of your product. Link directly to the image, not the page where it is located. Same rules apply as main_image. You can specify one or more additional images separated by the character '|'
  # 2. callback: err, product.
  # - - -
  createProduct: (product, callback) ->
    @createProductJSON product
      .then (json) => @format json.data
      .nodeify callback
  
  createProductJSON: (product, callback) ->
    @post '/product/add', product
    .nodeify(callback)
  
  # `updateProduct( product, [callback] )`
  #
  # Update a Product
  #
  # Arguments
  # 1. product
  #   * id: Must provide either id or parent_sku Wish's unique identifier for the product you would like to update
  #   * parent_sku: Must provide either id or parent_sku The parent sku for the product you would like to update
  #   * name: *optional* Name of the product as shown to users
  #   * description: *optional* Description of the product. If you want a new line use "\n".
  #   * tags: *optional* Comma separated list of strings. The tags passed into this parameter will completely replace the tags that are currently on the product
  #   * brand: *optional* Brand or manufacturer of your product
  #   * landing_page_url: *optional* URL on your website containing the product detail and buy button for the applicable product.
  #   * upc: *optional* 12-digit Universal Product Codes (UPC)-contains no letters or other characters
  #   * main_image: *optional* URL of a photo of your product. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  #   * extra_images: *optional* URL of a photo of your product. Link directly to the image, not the page where it is located. Same rules apply as main_image. You can specify one or more additional images separated by the character '|'
  # 2. callback: err, null
  # - - -
  updateProduct: (product, callback) ->
    @updateProductJSON product
      .then (json) => json.data
      .nodeify callback
  
  updateProductJSON: (product, callback) ->
    @post '/product/update', product
    .nodeify(callback)
  
  # enableProduct( {id/parent_sku}, [callback] )`
  # 
  # Enable a Product
  #
  # Arguments
  # 1. object
  #   * id: Must provide either id or parent_sku Wish's unique identifier for the product you would like to update
  #   * parent_sku: Must provide either id or parent_sku The parent sku for the product you would like to update
  # 2. callback: err, {}
  # - - -
  enableProduct: (args, callback) ->
    @enableProductJSON args
      .then (json) => json.data
      .nodeify callback
  
  enableProductJSON: (args, callback) ->
    @post '/product/enable', args
    .nodeify(callback)
  
  # `disableProduct( {id/parent_sku}, [callback] )`
  #
  # Disable a Product
  #
  # Arguments same as `enableProduct`
  # - - -
  disableProduct: (args, callback) ->
    @disableProductJSON args
      .then (json) => json.data
      .nodeify callback
  
  disableProductJSON: (args, callback) ->
    @post '/product/disable', args
    .nodeify(callback)
  
  
  # Variation
  # ---------
  #
  # `variant( sku, [callback] )`
  #
  # Retrieves the details of an existing product variation.
  #
  # Be careful: SKU is case sensitive.
  #
  # Arguments
  #
  # 1. sku
  # 2. callback: err, variant
  # - - -
  variant: (sku, callback) ->
    @variantJSON sku
      .then (json) => @format json.data
      .nodeify callback
  
  variantJSON: (sku, callback) ->
    @get '/variant', sku: sku
      .nodeify callback
  
  # `variants( [start], [limit], [callback] )`
  #
  # List all Product Variations
  #
  # Be careful: The limit is product count limit. Not variants limit.
  #
  # Arguments
  #
  # 1. start: *optional* An offset into the list of returned items. Use 0 to start at the beginning. The API will return the requested number of items starting at this offset. Default to 0 if not supplied
  # 2. limit: A limit on the number of products that can be returned. Limit can range from 1 to 500 items and the default is 50
  # 3. callback: err, variants
  # - - -
  variants: (start, limit, callback) ->
    @variantsJSON start, limit
      .then (json) => @format json.data
      .nodeify callback
  
  variantsJSON: (start = 0, limit = 50, callback) ->
    @get '/variant/multi-get',
      start: start
      limit: limit
    .nodeify callback
  
  # `createVariant( variant, [callback] )`
  #
  # Create a Product Variation
  #
  # Arguments
  # 1. variant
  #   * parent_sku: The parent_sku of the product this new product variation should be added to. If the product is missing a parent_sku, then this should be the SKU of a product variation of the product
  #   * sku: The unique identifier that your system uses to recognize this variation
  #   * color: *optional* The color of the variation. Example: red, blue, green
  #   * size: *optional* The size of the variation. Example: Large, Medium, Small, 5, 6, 7.5
  #   * inventory: The physical quantities you have for this variation
  #   * price: The price of the variation when the user purchases one
  #   * shipping: The shipping of the variation when the user purchases one
  #   * msrp: *optional* Manufacturer's Suggested Retail Price. This field is recommended as it will show as a strikethrough price on Wish and appears above the selling price for the variation.
  #   * shipping_time: *optional* The amount of time it takes for the shipment to reach the buyer. Please also factor in the time it will take to fulfill and ship the item. Provide a time range in number of days. Lower bound cannot be less than 2 days. Example: 15-20
  #   * main_image: URL of a photo of your product. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  # 2. callback: err, variant
  # - - -
  createVariant: (variant, callback) ->
    @createVariantJSON variant
      .then (json) => @format json.data
      .nodeify callback
  
  createVariantJSON: (variant, callback) ->
    @post '/variant/add', variant
    .nodeify(callback)
  
  # `updateVariant( variant, [callback] )`
  # 
  # Update a Product Variation
  #
  # Arguments
  #
  # 1. variant
  #   * sku: The unique identifier for the variation you would like to update
  #   * inventory: *optional* The physical quantities you have for this variation
  #   * price: *optional* The price of the variation when the user purchases one
  #   * shipping: *optional* The shipping of the variation when the user purchases one
  #   * enabled: *optional* True if the variation is for sale, False if you need to halt sales.
  #   * size: *optional* The size of the variation. Example: Large, Medium, Small, 5, 6, 7.5
  #   * color: *optional* The color of the variation. Example: red, blue, green
  #   * msrp: *optional* Manufacturer's Suggested Retail Price.
  #   * shipping_time: *optional* The amount of time it takes for the shipment to reach the buyer. Please also factor in the time it will take to fulfill and ship the item. Provide a time range in number of days. Lower bound cannot be less than 2 days. Example: 5-10
  #   * main_image: *optional* URL of a photo for this variant. Provide this when you have different pictures for different variant of the product. If left out, it'll use the main_image of the productwith the provided parent_sku. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  # 2. callback: err, {}
  # - - -
  updateVariant: (variant, callback) ->
    @updateVariantJSON variant
      .then (json) => json.data
      .nodeify callback
  
  updateVariantJSON: (variant, callback) ->
    @post '/variant/update', variant
    .nodeify(callback)
  
  # `enableVariant( sku, [callback] )`
  #
  # Enable a Product Variation
  #
  # Arguments
  #
  # 1. sku: The unique identifier for the item you would like to update
  # 2. callback: err, {}
  # - - -
  enableVariant: (sku, callback) ->
    @enableVariantJSON sku
      .then (json) => json.data
      .nodeify callback
  
  enableVariantJSON: (sku, callback) ->
    @post '/variant/enable', sku: sku
    .nodeify(callback)
  
  # `disableVariant( sku, [callback] )`
  #
  # Disable a Product Variation
  #
  # Arguments same as `enableVariant`
  # - - -
  disableVariant: (sku, callback) ->
    @disableVariantJSON sku
      .then (json) => json.data
      .nodeify callback
  
  disableVariantJSON: (sku, callback) ->
    @post '/variant/disable', sku: sku
    .nodeify(callback)
    
  
  # Order
  # ---------
  #
  # `order( id, [callback] )`
  #
  # Retrieves the details of an existing order.
  #
  # Arguments
  #
  # 1. id
  # 2. callback: err, order
  # - - -
  order: (id, callback) ->
    @orderJSON id
      .then (json) => @format json.data
      .nodeify callback
      
  orderJSON: (id, callback) ->
    @get '/order', id: id
      .nodeify callback

  # `orders( [start], [limit], [since], [callback] )`
  #
  # Retrieve Recently Changed Orders
  #
  # Arguments
  #
  # 1. start: *optional* An offset into the list of returned items. Use 0 to start at the beginning. The API will return the requested number of items starting at this offset. Default to 0 if not supplied
  # 2. limit: *optional* A limit on the number of products that can be returned. Limit can range from 1 to 500 items and the default is 50
  # 3. since: *optional* Collect all the orders that have been updated since the time value passed into this parameter. Fetches from beginning of time if not specified. We accept 2 formats, one with precision down to day and one with precision down to seconds. Example: `Jan 20th, 2014` is `2014-01-20`, `Jan 20th, 2014 20:10:20` is `2014-01-20T20:10:20`.
  # 4. callback: err, orders.
  # - - -
  orders: (start, limit, since, callback) ->
    @ordersJSON start, limit, since
      .then (json) => @format json.data
      .nodeify callback
      
  ordersJSON: (start = 0, limit = 50, since = '', callback) ->
    @get '/order/multi-get',
      start: start
      limit: limit
      since: since
    .nodeify callback
  
  # `unfullfiledOrders( [start], [limit], [since], [callback] )`
  #
  # Retrieve Unfulfilled Orders
  #
  # Arguments same as `orders`
  # - - -
  unfullfiledOrders: (start, limit, since, callback) ->
    @unfullfiledOrdersJSON start, limit, since
      .then (json) => @format json.data
      .nodeify callback
      
  unfullfiledOrdersJSON: (start = 0, limit = 50, since = '', callback) ->
    @get '/order/get-fulfill',
      start: start
      limit: limit
      since: since
    .nodeify callback
  
  # `fulfillOrder( order, [callback] )`
  #
  # Fulfill an order
  #
  # Arguments
  #
  # 1. order
  #   * id: Wish's unique identifier for the order, or 'order_id' in the Order object
  #   * tracking_provider: The carrier that will be shipping your package to its destination
  #   * tracking_number: *optional* The unique identifier that your carrier provided so that the user can track their package as it is being delivered. Tracking number should only contain alphanumeric characters with no space between them.
  #   * ship_note: *optional* A note to the user when you marked the order as shipped
  # 2. callback: err, { success: true }
  # - - -
  fulfillOrder: (order, callback) ->
    @fulfillOrderJSON order
      .then (json) => @format json.data
      .nodeify callback
  
  fulfillOrderJSON: (order, callback) ->
    @post '/order/fulfill-one', order
    .nodeify(callback)
  
  # `refundOrder( args, [callback] )`
  #
  # Refund/Cancel an order
  #
  # Arguments
  # 1. object
  #   * id: Wish's unique identifier for the order, or 'order_id' in the Order object
  #   * reason_code: An integer representing the reason for the refund. Check the table between for accepted reason codes
  #     * 0 No More Inventory
  #     * 1 Unable to Ship
  #     * 2 Customer Requested Refund
  #     * 3 Item Damaged
  #     * 7 Received Wrong Item
  #     * 8 Item does not Fit
  #     * 9 Arrived Late or Missing
  #     * -1 Other, if none of the reasons above apply. reason_note is required if this is used asreason_code
  #   * reason_note: *optional* A note to the user explaining reason for the refund. This field is required if reason_code is -1(Other)
  # 2. callback: err, { success: true }
  # - - -
  refundOrder: (args, callback) ->
    @refundOrderJSON args
      .then (json) => @format json.data
      .nodeify callback
  
  cancelOrder: (args, callback) ->
    @refundOrder args, callback
  
  refundOrderJSON: (args, callback) ->
    @post '/order/refund', args
    .nodeify(callback)
  
  # `modifyOrder( args, [callback] )`
  #
  # Modify Tracking of a Shipped Order
  #
  # Arguments
  #
  # 1. object
  #   * id: Wish's unique identifier for the order, or 'order_id' in the Order object
  #   * tracking_provider: The carrier that will be shipping your package to its destination
  #   * tracking_number: *optional* The unique identifier that your carrier provided so that the user can track their package as it is being delivered. Tracking number should only contain alphanumeric characters with no space between them.
  #   * ship_note: *optional* A note to the user when you marked the order as shipped
  # 2. callback: err, { success: true }
  # - - -
  modifyOrder: (args, callback) ->
    @modifyOrderJSON args
      .then (json) => @format json.data
      .nodeify callback
  
  modifyOrderJSON: (args, callback) ->
    @post '/order/modify-tracking', args
    .nodeify(callback)
  