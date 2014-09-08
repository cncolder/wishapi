url = require 'url'
_ = require 'lodash'
Promise = require 'bluebird'
request = Promise.promisifyAll require 'request'
errors = require './errors'
debug = (require './debug') 'merchant'


module.exports = class Merchant
  constructor: ({ @key, @sandbox, @timeout }) ->
    @sandbox ?= false
    @timeout ?= 20 * 1000

    @baseUrl = if @sandbox
      'https://sandbox.merchant.wish.com/api/v1'
    else
      'https://merchant.wish.com/api/v1'
  
  format: (json) ->
    if _.isArray json
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
      if { ShippingDetail } = json
        _.assign json, ShippingDetail
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
    _.assign uri.query, query, key: @key
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
    return Promise.reject new errors.ParamError if not @key
    
    uri = @url path, query
    
    debug 'GET', uri
    
    @handle request.getAsync uri,
      json:    true
      timeout: @timeout
    
  post: (path, form) ->
    return Promise.reject new errors.ParamError if not @key
    
    uri = @url path
    form.key = @key
    
    debug 'POST', uri, form
    
    @handle request.postAsync url,
      json:    true
      timeout: @timeout
      form:    form
  
  authTestJSON: (callback) ->
    @get '/auth_test'
      .nodeify callback
  
  authTest: (callback) ->
    @authTestJSON()
      .then (json) => @format json.data
      .nodeify callback
  
  productJSON: (id, callback) ->
    @get '/product', id: id
      .nodeify callback
  
  product: (id, callback) ->
    @productJSON id
      .then (json) => @format json.data
      .nodeify callback
  
  productsJSON: (start = 0, limit = 50, callback) ->
    @get '/product/multi-get',
      start: start
      limit: limit
    .nodeify callback
  
  products: (start, limit, callback) ->
    @productsJSON start, limit
      .then (json) => @format json.data
      .nodeify callback
  
  variantJSON: (sku, callback) ->
    @get '/variant', sku: sku
      .nodeify callback
  
  # sku is case sensitive
  variant: (sku, callback) ->
    @variantJSON sku
      .then (json) => @format json.data
      .nodeify callback
  
  variantsJSON: (start = 0, limit = 50, callback) ->
    @get '/variant/multi-get',
      start: start
      limit: limit
    .nodeify callback
  
  variants: (start, limit, callback) ->
    @variantsJSON start, limit
      .then (json) => @format json.data
      .nodeify callback
  
  orderJSON: (id, callback) ->
    @get '/order', id: id
      .nodeify callback
  
  order: (id, callback) ->
    @orderJSON id
      .then (json) => @format json.data
      .nodeify callback