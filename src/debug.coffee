debug = require 'debug'


module.exports = (name) ->
  debug = debug "wishapi:#{name}"
  
  if process.memoryUsage
    mb = (n) -> Math.round n * 0.000001
    
    debug.mem = ->
      { rss, heapTotal, heapUsed } = do process.memoryUsage
      
      debug "rss: #{mb rss} MB, heap: #{mb heapUsed}/#{mb heapTotal} MB"
      
  debug
