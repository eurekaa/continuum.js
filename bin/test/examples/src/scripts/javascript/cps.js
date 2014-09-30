var test = function(test, !!){
   return (typeof test === 'string');
};
exports['test'] = function(!!){
   result = test('test', !!);
   return result;
};