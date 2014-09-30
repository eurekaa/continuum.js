test = (test, !!)-> return typeof test is 'string'
exports['test'] = (!!)->
   result = test 'test', !!
   return result