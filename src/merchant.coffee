util = require 'util'
url = require 'url'
Promise = require 'bluebird'
request = Promise.promisifyAll require 'request'
errors = require './errors'
debug = (require './debug') 'merchant'


###
Merchant
========

**Merchant** use for invoke [Wish Merchant API](https://merchant.wish.com/documentation/api). For more infomation please visit [The Wish merchant platform](https://merchant.wish.com).
###
module.exports = class Merchant
  
  ###
  new Merchant
  ------------
  
  create a new instance.
  
  * key: Api key of wish. Read [official document](https://merchant.wish.com/documentation/api#get-api-key) for more info.
  * sandbox: If `true` will invoke sandbox api for test. Default `false`.
  * timeout: Milliseconds wait the respond of api. Default 20s (20 * 1000).
  
  return a new instance.
  
  ```coffee
  merchant = new Merchant key: 'your api key here'
  ```
  ###
  constructor: ({ @key, @sandbox, @timeout }) ->
    @sandbox ?= false
    @timeout ?= 20 * 1000

    @baseUrl = if @sandbox
      'https://sandbox.merchant.wish.com/api/v1'
    else
      'https://merchant.wish.com/api/v1'
  
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
  
  url: (path, query) ->
    uri = url.parse @baseUrl
    uri.pathname += path
    uri.path = ''
    uri.query ?= {}
    uri.query[key] = value for key, value of query
    # uri.query.key = @key
    url.format uri
  
  handle: (promise) ->
    promise
      .catch ([ res, body ]) ->
        debug 'HTTP Status', res.statusCode
      
        throw errors.http res.statusCode
      .then ([ res, body ]) ->
        debug body.code, body.message
      
        { code } = body
      
        if code is 0
          body
        else if code
          throw errors.wish body
        else
          throw errors.ServerError response: body
  
  get: (path, query = {}) ->
    return Promise.reject new errors.ParamMissingError if not @key
    
    query.key = @key
    uri = @url path, query
    
    debug 'GET', uri
    
    @handle request.getAsync uri,
      json:    true
      timeout: @timeout
    
  post: (path, form = {}) ->
    return Promise.reject new errors.ParamMissingError if not @key
    
    uri = @url path
    form.key = @key
    
    debug 'POST', uri, form
    
    @handle request.postAsync uri,
      json:    true
      timeout: @timeout
      form:    form
  
  ###
  Authentication
  --------------
  
  Test if api key is valid.
  
  return `{success: true}` if success. otherwise error.
  ###
  authTest: (callback) ->
    @authTestJSON()
      .then (json) => @format json.data
      .nodeify callback
  
  authTestJSON: (callback) ->
    @get '/auth_test'
      .nodeify callback
  
  ###
  Product
  -------
  
  Retrieve the details about a product which exists on the Wish platform.

  * id: The unique wish identifier for this product
  
  return a product data.
  ###
  product: (id, callback) ->
    @productJSON id
      .then (json) => @format json.data
      .nodeify callback
  
  productJSON: (id, callback) ->
    @get '/product', id: id
      .nodeify callback
  
  ###
  List all Products

  * start: **optional** An offset into the list of returned items. Use 0 to start at the beginning. The API will return the requested number of items starting at this offset. Default to 0 if not supplied.
  * limit: **optional** A limit on the number of products that can be returned. Limit can range from 1 to 500 items and the default is 50
  
  return an product array.
  ###
  products: (start, limit, callback) ->
    @productsJSON start, limit
      .then (json) => @format json.data
      .nodeify callback
  
  productsJSON: (start = 0, limit = 50, callback) ->
    @get '/product/multi-get',
      start: start
      limit: limit
    .nodeify callback
  
  ###
  Create a Product
  
  * name: Name of the product as shown to users on Wish
  * description: Description of the product. Should not contain HTML. If you want a new line use "\n".
  * tags: Comma separated list of strings that describe the product. Only 10 are allowed. Any tags past 10 will be ignored.
  * sku: The unique identifier that your system uses to recognize this product
  * color: optional The color of the product. Example: red, blue, green
  * size: optional The size of the product. Example: Large, Medium, Small, 5, 6, 7.5
  * inventory: The physical quantities you have for this product
  * price: The price of the product when the user purchases one
  * shipping: The shipping of the product when the user purchases one
  * msrp: optional Manufacturer's Suggested Retail Price. This field is recommended as it will show as a strikethrough price on Wish and appears above the selling price for the product.
  * shipping_time: optional The amount of time it takes for the shipment to reach the buyer. Please also factor in the time it will take to fulfill and ship the item. Provide a time range in number of days. Lower bound cannot be less than 2 days. Example: 15-20
  * main_image: URL of a photo of your product. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  * parent_sku: **optional** When defining a variant of a product we must know which product to attach the variation to. parent_sku is the unique id of the product that you can use later when using the add product variation API.
  * brand: optional Brand or manufacturer of your product
  * landing_page_url: optional URL on your website containing the product details
  * upc: optional 12-digit Universal Product Codes (UPC)-contains no letters or other characters
  * extra_images: optional URL of extra photos of your product. Link directly to the image, not the page where it is located. Same rules apply as main_image. You can specify one or more additional images separated by the character '|'
  ###
  createProduct: (args, callback) ->
    @createProductJSON args
      .then (json) => @format json.data
      .nodeify callback
  
  createProductJSON: (args, callback) ->
    @post '/product/add', args
    .nodeify(callback)
  
  ###
  Update a Product
  
  * id: Must provide either id or parent_sku Wish's unique identifier for the product you would like to update
  * parent_sku: Must provide either id or parent_sku The parent sku for the product you would like to update
  * name: optional Name of the product as shown to users
  * description: optional Description of the product. If you want a new line use "\n".
  * tags: optional Comma separated list of strings. The tags passed into this parameter will completely replace the tags that are currently on the product
  * brand: optional Brand or manufacturer of your product
  * landing_page_url: optional URL on your website containing the product detail and buy button for the applicable product.
  * upc: optional 12-digit Universal Product Codes (UPC)-contains no letters or other characters
  * main_image: optional URL of a photo of your product. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  * extra_images: optional URL of a photo of your product. Link directly to the image, not the page where it is located. Same rules apply as main_image. You can specify one or more additional images separated by the character '|'
  ###
  updateProduct: (args, callback) ->
    @updateProductJSON args
      .then (json) => json.data
      .nodeify callback
  
  updateProductJSON: (args, callback) ->
    @post '/product/update', args
    .nodeify(callback)
  
  ###
  Enable a Product
  
  * id: Must provide either id or parent_sku Wish's unique identifier for the product you would like to update
  * parent_sku: Must provide either id or parent_sku The parent sku for the product you would like to update
  ###
  enableProduct: (args, callback) ->
    @enableProductJSON args
      .then (json) => json.data
      .nodeify callback
  
  enableProductJSON: (args, callback) ->
    @post '/product/enable', args
    .nodeify(callback)
  
  ###
  Disable a Product
  
  * id: Must provide either id or parent_sku Wish's unique identifier for the product you would like to update
  * parent_sku: Must provide either id or parent_sku The parent sku for the product you would like to update
  ###
  disableProduct: (args, callback) ->
    @disableProductJSON args
      .then (json) => json.data
      .nodeify callback
  
  disableProductJSON: (args, callback) ->
    @post '/product/disable', args
    .nodeify(callback)
  
  
  ###
  Variation
  ---------
  
  Retrieves the details of an existing product variation.
  
  Be careful: SKU is case sensitive.
  ###
  variant: (sku, callback) ->
    @variantJSON sku
      .then (json) => @format json.data
      .nodeify callback
  
  variantJSON: (sku, callback) ->
    @get '/variant', sku: sku
      .nodeify callback
  
  ###
  List all Product Variations
  ###
  variants: (start, limit, callback) ->
    @variantsJSON start, limit
      .then (json) => @format json.data
      .nodeify callback
  
  variantsJSON: (start = 0, limit = 50, callback) ->
    @get '/variant/multi-get',
      start: start
      limit: limit
    .nodeify callback
    
  ###
  Create a Product Variation
  
  * parent_sku: The parent_sku of the product this new product variation should be added to. If the product is missing a parent_sku, then this should be the SKU of a product variation of the product
  * sku: The unique identifier that your system uses to recognize this variation
  * color: optional The color of the variation. Example: red, blue, green
  * size: optional The size of the variation. Example: Large, Medium, Small, 5, 6, 7.5
  * inventory: The physical quantities you have for this variation
  * price: The price of the variation when the user purchases one
  * shipping: The shipping of the variation when the user purchases one
  * msrp: optional Manufacturer's Suggested Retail Price. This field is recommended as it will show as a strikethrough price on Wish and appears above the selling price for the variation.
  * shipping_time: optional The amount of time it takes for the shipment to reach the buyer. Please also factor in the time it will take to fulfill and ship the item. Provide a time range in number of days. Lower bound cannot be less than 2 days. Example: 15-20
  * main_image: URL of a photo of your product. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  ###
  createVariant: (args, callback) ->
    @createVariantJSON args
      .then (json) => @format json.data
      .nodeify callback
  
  createVariantJSON: (args, callback) ->
    @post '/variant/add', args
    .nodeify(callback)
  
  ###
  Update a Product Variation
  
  * sku: The unique identifier for the variation you would like to update
  * inventory: optional The physical quantities you have for this variation
  * price: optional The price of the variation when the user purchases one
  * shipping: optional The shipping of the variation when the user purchases one
  * enabled: optional True if the variation is for sale, False if you need to halt sales.
  * size: optional The size of the variation. Example: Large, Medium, Small, 5, 6, 7.5
  * color: optional The color of the variation. Example: red, blue, green
  * msrp: optional Manufacturer's Suggested Retail Price.
  * shipping_time: optional The amount of time it takes for the shipment to reach the buyer. Please also factor in the time it will take to fulfill and ship the item. Provide a time range in number of days. Lower bound cannot be less than 2 days. Example: 5-10
  * main_image: optional URL of a photo for this variant. Provide this when you have different pictures for different variant of the product. If left out, it'll use the main_image of the product with the provided parent_sku. Link directly to the image, not the page where it is located. We accept JPEG, PNG or GIF format. Images should be at least 100 x 100 pixels in size.
  ###
  updateVariant: (args, callback) ->
    @updateVariantJSON args
      .then (json) => json.data
      .nodeify callback
  
  updateVariantJSON: (args, callback) ->
    @post '/variant/update', args
    .nodeify(callback)
  
  ###
  Enable a Product Variation
  
  * sku: The unique identifier for the item you would like to update
  ###
  enableVariant: (sku, callback) ->
    @enableVariantJSON sku
      .then (json) => json.data
      .nodeify callback
  
  enableVariantJSON: (sku, callback) ->
    @post '/variant/enable', sku: sku
    .nodeify(callback)
  
  ###
  Disable a Product Variation
  
  * sku: The unique identifier for the item you would like to update
  ###
  disableVariant: (sku, callback) ->
    @disableVariantJSON sku
      .then (json) => json.data
      .nodeify callback
  
  disableVariantJSON: (sku, callback) ->
    @post '/variant/disable', sku: sku
    .nodeify(callback)
    
  
  ###
  Order
  ---------
  
  Retrieves the details of an existing order.
  ###
  order: (id, callback) ->
    @orderJSON id
      .then (json) => @format json.data
      .nodeify callback
      
  orderJSON: (id, callback) ->
    @get '/order', id: id
      .nodeify callback

  ###
  Retrieve Recently Changed Orders
  
  * start: optional An offset into the list of returned items. Use 0 to start at the beginning. The API will return the requested number of items starting at this offset. Default to 0 if not supplied
  * limit: optionalA limit on the number of products that can be returned. Limit can range from 1 to 500 items and the default is 50
  * since: optional Collect all the orders that have been updated since the time value passed into this parameter. Fetches from beginning of time if not specified. We accept 2 formats, one with precision down to day and one with precision down to seconds. Example: Jan 20th, 2014 is 2014-01-20, Jan 20th, 2014 20:10:20 is 2014-01-20T20:10:20.
  ###
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
  
  ###
  Retrieve Unfulfilled Orders
  
  * start: optional An offset into the list of returned items. Use 0 to start at the beginning. The API will return the requested number of items starting at this offset. Default to 0 if not supplied
  * limit: optionalA limit on the number of products that can be returned. Limit can range from 1 to 500 items and the default is 50
  * since: optional Collect all the orders that have been updated since the time value passed into this parameter. Fetches from beginning of time if not specified. We accept 2 formats, one with precision down to day and one with precision down to seconds. Example: Jan 20th, 2014 is 2014-01-20, Jan 20th, 2014 20:10:20 is 2014-01-20T20:10:20.
  ###
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
  
  ###
  Fulfill an order
  
  * id: Wish's unique identifier for the order, or 'order_id' in the Order object
  * tracking_provider: The carrier that will be shipping your package to its destination
  * tracking_number: optional The unique identifier that your carrier provided so that the user can track their package as it is being delivered. Tracking number should only contain alphanumeric characters with no space between them.
  * ship_note: optional A note to the user when you marked the order as shipped
  ###
  fulfillOrder: (args, callback) ->
    @fulfillOrderJSON args
      .then (json) => @format json.data
      .nodeify callback
  
  fulfillOrderJSON: (args, callback) ->
    @post '/order/fulfill-one', args
    .nodeify(callback)
  
  ###
  Refund/Cancel an order
  
  * id: Wish's unique identifier for the order, or 'order_id' in the Order object
  * reason_code: An integer representing the reason for the refund. Check the table between for accepted reason codes
  * reason_note: optional A note to the user explaining reason for the refund. This field is required if reason_code is -1(Other)
  
  Refund Reason Codes
  0 No More Inventory
  1 Unable to Ship
  2 Customer Requested Refund
  3 Item Damaged
  7 Received Wrong Item
  8 Item does not Fit
  9 Arrived Late or Missing
  -1 Other, if none of the reasons above apply. reason_note is required if this is used as reason_code
  ###
  refundOrder: (args, callback) ->
    @refundOrderJSON args
      .then (json) => @format json.data
      .nodeify callback
  
  cancelOrder: (args, callback) ->
    @refundOrder args, callback
  
  refundOrderJSON: (args, callback) ->
    @post '/order/refund', args
    .nodeify(callback)
  
  ###
  Modify Tracking of a Shipped Order
  
  * id: Wish's unique identifier for the order, or 'order_id' in the Order object
  * tracking_provider: The carrier that will be shipping your package to its destination
  * tracking_number: optional The unique identifier that your carrier provided so that the user can track their package as it is being delivered. Tracking number should only contain alphanumeric characters with no space between them.
  * ship_note: optional A note to the user when you marked the order as shipped
  ###
  modifyOrder: (args, callback) ->
    @modifyOrderJSON args
      .then (json) => @format json.data
      .nodeify callback
  
  modifyOrderJSON: (args, callback) ->
    @post '/order/modify-tracking', args
    .nodeify(callback)
    