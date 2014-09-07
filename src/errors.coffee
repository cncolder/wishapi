errors = require 'errors'


errors.create
  name: 'KeyError'
  defaultMessage: 'Required Param key Missing'
  code: 1001

errors.create
  name: 'AuthError'
  defaultMessage: 'Unauthorized Request'
  code: 4000

errors.create
  name: 'WishError'
  code: 4001

errors.create
  name: 'ServerError'
  defaultMessage: 'Server Return Unknown Contest.'
  defaultExplanation: 'Maybe server is maintaining.'
  code: 911

errors.wish = (body) ->
  { code } = body
  FoundError = errors.find code
  
  delete body.code
  
  new FoundError body

errors.http = (code) ->
  HttpError = errors.find code
  
  new HttpError


module.exports = errors
