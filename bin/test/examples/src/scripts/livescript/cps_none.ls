test = (test, callback)-> callback null, (typeof test is 'string')
exports['test'] = (callback)->
   test 'test', (err, result)->
      callback err, result