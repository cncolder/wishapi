# Some Errors
# ===============================
# 
# The bluebird Promise can catch error by the error type.
# So we define some special error here.
# 
# ```coffee
# api.variant sku: '0'
# .then (v) ->
#   console.log v.price
# .catch (NotFoundError, err) ->
#   console.error 'are you sure you provide a right sku?'
# .catch (AuthError, err) ->
#   console.error 'oh! we need key!'
# .catch (Http500Error, err) ->
#   console.error 'wish tired.'
# 
# ```
module.exports = errors = require 'errors'


# **ParamInvalidError**
# 
# Raise when you provide some invalid param. eg. get order id '0'.
# 
# Wish is only check a little param. product id '0' will return not found error.
errors.create
  name: 'ParamInvalidError'
  code: 1000

# **ParamMissingError**
# 
# Raise when you missing some *must provide* param. eg. missing api key.
errors.create
  name: 'ParamMissingError'
  defaultMessage: 'Required Param Missing'
  code: 1001

# **NotFoundError**
# 
# Raise when you query some model but there is not that model. eg. wrong product id.
errors.create
  name: 'NotFoundError'
  code: 1004

# **AuthError**
# 
# Raise when you provide a wrong api key.
errors.create
  name: 'AuthError'
  defaultMessage: 'Unauthorized Request'
  code: 4000

# **ServerError**
# 
# Raise when wish down or return a mistake format data for us. eg. html page.
errors.create
  name: 'ServerError'
  defaultMessage: 'Server Return Unknown Contest.'
  defaultExplanation: 'Maybe server is maintaining.'
  code: 911

# Find and return special wish error by code.
errors.wish = (body) ->
  { code } = body
  FoundError = errors.find code
  
  delete body.code
  
  new FoundError body

# Find and return special http error by status code.
errors.http = (code) ->
  HttpError = errors.find code
  
  new HttpError
