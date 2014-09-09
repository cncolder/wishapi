try
  debug = require 'debug'
catch


module.exports = (name) ->
  if debug
    debug "wishapi:#{name}"
  else
    ->
