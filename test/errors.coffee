{ debug, assert } = require './helpers'
errors = require '../src/errors'


describe 'errors', ->
  describe 'code', ->
    it 'should have an error with code 1000', ->
      error = new errors.ParamInvalidError()
      assert.equal error.code, 1000
    
    it 'should have an error with code 1001', ->
      error = new errors.ParamMissingError()
      assert.equal error.code, 1001
    
    it 'should have an error with code 4000', ->
      error = new errors.AuthError()
      assert.equal error.code, 4000
  
  describe 'wish', ->
    it 'should find error by wish respond body then return a new instance', ->
      error = errors.wish code: 4000
      assert.instanceOf error, errors.AuthError
  
  describe 'http', ->
    it 'should find http error by status code', ->
      error = errors.http 404
      assert.instanceOf error, errors.Http404Error
      