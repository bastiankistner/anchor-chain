anchor = require 'anchor'
_ = require 'lodash'

###
  params can either be
  
  1. validationValue, {type: 'type', minLength: 20} etc.  
  2. validationObject, {type: 'type', minLength: 20} etc., data to test as object 
  
  
  2.) 
    conserves the property name that we can sent back afterwards
    validationObject needs to be like the following
  [
    { key: 'keyName to test', type: 'type', maxLength: 20 }
    { key: 'keyName2', type: 'string', minLength: 20 }  
  ]
  
  both options should take care, that there is an additional key in the error object e. g. for minLength
  those keys are not created for non-type validations ==> therefore we need to take care of this on our own
  
  ###
module.exports = anchorChain = (validationSource, validationParams) ->

  if (arguments.length != 2)
    err = new Error('Valdation requires exactly two parameters. Either validationObjectArray and data or validationValue and anchor validationRuleObject.')
    throw err;
    
  
  if _.isArray(validationSource)
    data = validationParams
    errors = []

    _.forEach validationSource, (source) ->
      validationParams = _.clone(source)
      delete validationParams['key']

      if data[source.key] != undefined

        _errors = anchor(data[source.key]).to(validationParams)
        if _errors
          errors = errors.concat enhanceErrors(_errors, validationParams, source.key)

    if errors.length == 0 then return false
    else return errors

    # if there are 2 params only, we have value as first param and validationParams as second param
  else
    errors = anchor(validationSource).to(validationParams)
    return enhanceErrors(errors, validationParams)



enhanceErrors = (errors, validationParams, validationKey) ->
  return errors unless errors

  addExpectedAndKey = (errorObject) ->
    # add the property name that was tested

    if ((typeof errorObject.property == 'undefined' || errorObject.property == 'undefined') && typeof validationKey == 'string')
      errorObject.property = validationKey
      if typeof errorObject.message == 'string'
        errorObject.message = errorObject.message.replace('undefined', validationKey)

    # add the expected value to each error if it's not the type property
    unless errorObject['expectedType']
      errorObject.expected = validationParams[errorObject.rule]

    return errorObject

  return errors.map addExpectedAndKey 