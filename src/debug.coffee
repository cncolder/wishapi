debug = require 'debug'


module.exports = (name) ->
  d = debug "wishapi:#{name}"
  
  if process.memoryUsage
    mb = (n) -> Math.round n * 0.000001
    
    d.mem = ->
      { rss, heapTotal, heapUsed } = do process.memoryUsage
      
      debug "rss: #{mb rss} MB, heap: #{mb heapUsed}/#{mb heapTotal} MB"
      
  d
