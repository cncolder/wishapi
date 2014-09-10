path = require 'path'
{ assert } = require './helpers'


describe 'debug', ->
  describe 'dependency resolve', ->
    it 'should be wishapi:test', ->
      debug = (require '../src/debug') 'test'
      assert.equal debug.namespace, 'wishapi:test'
      
  describe 'dependency not found', ->
    Module = require 'module'
    { load } = Module.prototype
  
    before ->
      delete require.cache[key] for key of require.cache when /\/debug/.test key
        
      Module.prototype.load = (filename) ->
        if /\/node_modules\/debug/.test filename
          load.call @, filename.replace 'debug', 'put debug into black hole let npm cannot find'
        else
          load.call @, filename
    
    after ->
      Module.prototype.load = load
  
    it 'should be noop', ->
      debug = (require '../src/debug') 'test'
      assert.isFunction debug
      assert.isUndefined debug.namespace
      assert.doesNotThrow -> debug 123
      assert.equal debug.toString(), 'function () {}'
