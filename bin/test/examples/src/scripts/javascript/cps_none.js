var test = function(test, callback){
   callback(null, (typeof test === 'string'));
};
exports['test'] = function(callback){
   test('test', function(err, result){
      callback(err, result);
   });
};