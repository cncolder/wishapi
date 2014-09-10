try
  debug = require 'debug'
catch


module.exports = (name) ->
  debug ?= -> ->
  debug "wishapi:#{name}"
