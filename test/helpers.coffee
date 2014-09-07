process.env.NODE_ENV = 'test'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'


{ assert, expect } = chai
should = do chai.should
chai.use chaiAsPromised


module.exports =
  assert: assert
  expect: expect
  should: should
  