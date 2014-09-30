test = (test, !!!)-> typeof test is 'string'
exports['test'] = (!!)->
   result = test 'test', !!
   return result
result = @.test !!!  
return result.value