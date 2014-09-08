process.env.NODE_ENV = 'test'
# TODO this not work
process.env.DEBUG = 'wishapi:*'

debug = (require '../src/debug') 'mocha'
nock = require 'nock'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'


{ assert, expect } = chai
should = do chai.should
chai.use chaiAsPromised

nock.disableNetConnect()
# do nock.recorder.rec


module.exports =
  debug:  debug
  assert: assert
  expect: expect
  should: should
  nock:   nock
