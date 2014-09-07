{ assert } = require './helpers'
Merchant = require '../src/merchant'
errors = require '../src/errors'


describe 'Merchant', ->
  sandbox = true
  key = ''
  
  it 'should run in sandbox when test', ->
    merchant = new Merchant
      sandbox: sandbox
    assert.equal merchant.baseUrl, 'https://sandbox.merchant.wish.com/api/v1'
  
  describe 'authTest', ->
    describe 'without key', ->
      it 'should reject KeyError', ->
        merchant = new Merchant
          sandbox: sandbox
        assert.isRejected merchant.authTest(), errors.KeyError
    
    describe 'with wrong key', ->
      it 'should reject AuthError', ->
        merchant = new Merchant
          sandbox: sandbox
          key: 'abc123haha='
        assert.isRejected merchant.authTest(), errors.AuthError
