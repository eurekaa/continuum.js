# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: examples
# Created: 22/07/14 19.28


async = require 'async'

# runtime options.
exports['options'] =
   input: path: 'examples/src'
   output: path: 'examples/bin'
   source_map: enabled: true, path: 'examples/map'
   cache: enabled: true, path: 'examples/cache'
   log: enabled: true, path: 'examples/log', name: 'test', levels: console: 'ALL', file: 'OFF'
   transformation: enabled: true, explicit: true


# *** COFFEESCRIPT ***
exports['scripts/coffeescript/cps_explicit'] = 
   extension: '.coffee'
   content: """
            'use cps'
            test = (test, !!!)-> typeof test is 'string'
            exports['test'] = (!!)->
               result = test 'test', !!
               return result
            result = @.test !!!  
            return result.value
            """

exports['scripts/coffeescript/cps_implicit'] = 
   extension: '.coffee'
   content: """
            test = (test, !!)-> return typeof test is 'string'
            exports['test'] = (!!)->
               result = test 'test', !!
               return result
            """

exports['scripts/coffeescript/cps_none'] =
   extension: '.coffee'
   content: """
            test = (test, callback)-> callback null, (typeof test is 'string')
            exports['test'] = (callback)->
               test 'test', (err, result)->
                  callback err, result
            """



# *** LIVESCRIPT ***
exports['scripts/livescript/cps_explicit'] = 
   extension: '.ls'
   content: """
            'use cps'
            test = (test, !!)-> return typeof test is 'string'
            exports['test'] = (!!)->
               result = test 'test', !!
               return result
            """

exports['scripts/livescript/cps_implicit'] =
   extension: '.ls'
   content: """
            test = (test, !!)-> return typeof test is 'string'
            exports['test'] = (!!)->
               result = test 'test', !!
               return result
            """

exports['scripts/livescript/cps_none'] =
   extension: '.ls'
   content: """
            test = (test, callback)-> callback null, (typeof test is 'string')
            exports['test'] = (callback)->
               test 'test', (err, result)->
                  callback err, result
            """


# *** JAVASCRIPT ***
exports['scripts/javascript/cps_explicit'] =
   extension: '.js'
   content: """
            'use cps'
            var test = function(test, !!){
               return (typeof test === 'string');
            };
            exports['test'] = function(!!){
               result = test('test', !!);
               return result;
            };
            """

exports['scripts/javascript/cps_implicit'] =
   extension: '.js'
   content: """
            var test = function(test, !!){
               return (typeof test === 'string');
            };
            exports['test'] = function(!!){
               result = test('test', !!);
               return result;
            };
            """

exports['scripts/javascript/cps_none'] =
   extension: '.js'
   content: """
            var test = function(test, callback){
               callback(null, (typeof test === 'string'));
            };
            exports['test'] = function(callback){
               test('test', function(err, result){
                  callback(err, result);
               });
            };
            """



# *** JADE ***
exports['pages/jade/page'] = 
   extension: '.jade'
   content: """
            doctype
            html
               head
                  title test continuum.js
               body
                  #test a jade test page.
                  footer
            """


# *** LESS ***
exports['styles/less/test'] = 
   extension: '.less'
   content: """
            @base: #f938ab;
            .box-shadow(@style, @c) when (iscolor(@c)) {
               -webkit-box-shadow: @style @c;
               box-shadow:         @style @c;
            }
            .box-shadow(@style, @alpha: 50%) when (isnumber(@alpha)) {
               .box-shadow(@style, rgba(0, 0, 0, @alpha));
            }
            .box {
               color: saturate(@base, 5%);
               border-color: lighten(@base, 30%);
               div { .box-shadow(0 0 5px, 30%) }
            }
            """


# *** STYLUS ***
exports['styles/stylus/test'] = 
   extension: '.styl'
   content: """
            border-radius()
               -webkit-border-radius: arguments
               -moz-border-radius: arguments
               border-radius: arguments

            body a
               font: 12px/1.4 "Lucida Grande", Arial, sans-serif
               background: black
               color: #ccc

            form input
               padding: 5px
               border: 1px solid
               border-radius: 5px
            """

# *** SASS ***
exports['styles/sass/test_sass'] =
   extension: '.sass'
   content: """
            .message
               border: 1px solid #ccc
               padding: 10px
               color: #333

            .success
               @extend .message
               border-color: green

            .error
               @extend .message
               border-color: red

            .warning
               @extend .message
               border-color: yellow
            """

exports['styles/sass/test_scss'] =
   extension: '.scss'
   content: """
            .message {
               border: 1px solid #ccc;
               padding: 10px;
               color: #333;
            }

            .success {
               @extend .message;
               border-color: green;
            }

            .error {
               @extend .message;
               border-color: red;
            }

            .warning {
               @extend .message;
               border-color: yellow;
            }
            """

# *** CSS ***
exports['styles/test'] =
   extension: '.css'
   content: """
            .box {
               color: #fe33ac;
               border-color: #fdcdea;
            }
            .box div {
               -webkit-box-shadow: 0 0 5px rgba(0, 0, 0, 0.3);
               box-shadow: 0 0 5px rgba(0, 0, 0, 0.3);
            }
            """


# *** NON COMPILABLE ***
exports['media/not_compilable'] =
   extension: '.txt'
   content: """
            this is a non compilable test file.
            """
