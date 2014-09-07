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
  
  handleRequest: (promise) ->
    promise
    .catch ([ res, body ]) ->
      throw errors.http res.statusCode
    .then ([ res, body ]) ->
      { code } = body
      
      if code is 0
        body
      else if code
        throw errors.wish body
      else
        throw errors.ServerError
          response: body
  
  get: (path) ->
    if not @key
      return Promise.reject new errors.KeyError
    
    url = "#{this.baseUrl}#{path}?key=#{this.key}"
    promise = request.getAsync url,
      json:    true
      timeout: @timeout
    
    @handleRequest promise
  
  post: (path, form) ->
    if not @key
      return Promise.reject new errors.KeyError
    
    url = "#{this.baseUrl}#{path}"
    form.key = @key
    
    promise = request.postAsync url,
      json:    true
      timeout: @timeout
      form:    form
    
    @handleRequest promise
  
  authTest: (callback) ->
    @get '/auth_test'
      .nodeify callback
