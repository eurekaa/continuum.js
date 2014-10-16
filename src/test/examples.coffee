# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: examples
# Created: 22/07/14 19.28


fs = require 'fs'

# runtime options.
exports['options'] =
   input: path: 'examples/src'
   output: path: 'examples/bin'
   temp: path: 'examples/tmp'
   source_map: enabled: true, path: 'examples/map'
   cache: enabled: true, path: 'examples/tmp/cache'
   log: enabled: true, path: 'examples/log', name: 'test', levels: console: 'ALL', file: 'OFF'
   transformation: enabled: true, explicit: true


# *** IMAGES ***
exports['media/images/logo'] = 
   extension: '.jpg'
   encoding: 'base64'
   content: fs.readFileSync '../media/images/logo.jpg', 'base64'

exports['media/images/logo2'] = 
   extension: '.png'
   encoding: 'base64'
   content: fs.readFileSync '../media/images/logo.png', 'base64'

exports['media/images/logo3'] =
   extension: '.gif'
   encoding: 'base64'
   content: fs.readFileSync '../media/images/logo.gif', 'base64'

exports['media/images/logo4'] =
   extension: '.tif'
   encoding: 'base64'
   content: fs.readFileSync '../media/images/logo.tif', 'base64'



# *** COFFEESCRIPT ***
exports['scripts/coffeescript/cps'] = 
   extension: '.coffee'
   encoding: 'utf8'
   content: """
            test = (test, !!!)-> typeof test is 'string'
            exports['test'] = (!!)->
               result = test 'test', !!
               return result
            result = @.test !!!  
            return result.value
            """

exports['scripts/coffeescript/cps_none'] =
   extension: '.coffee'
   encoding: 'utf8'
   content: """
            test = (test, callback)-> callback null, (typeof test is 'string')
            exports['test'] = (callback)->
               test 'test', (err, result)->
                  callback err, result
            """



# *** LIVESCRIPT ***
exports['scripts/livescript/cps'] =
   extension: '.ls'
   encoding: 'utf8'
   content: """
            test = (test, !!)-> return typeof test is 'string'
            exports['test'] = (!!)->
               result = test 'test', !!
               return result
            """

exports['scripts/livescript/cps_none'] =
   extension: '.ls'
   encoding: 'utf8'
   content: """
            test = (test, callback)-> callback null, (typeof test is 'string')
            exports['test'] = (callback)->
               test 'test', (err, result)->
                  callback err, result
            """


# *** JAVASCRIPT ***
exports['scripts/javascript/cps'] =
   extension: '.js'
   encoding: 'utf8'
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
   encoding: 'utf8'
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


# *** JSON ***
exports['data/references'] =
   extension: '.json'
   encoding: 'utf8'
   content: '{ "foo": true, "bar": { "baz": "#{bar}", "cool": [1, "#{stuff}", 3] }, "stuff": "there are #{bar.cool[2]} cool stuffs? #{bar.baz}", "test": "#{bar}" }'

###
exports['data/links'] =
   extension: '.json'
   encoding: 'utf8'
   content: '{ "foo": "@{references.json}" }'
###

# *** JADE ***
exports['pages/jade/page'] = 
   extension: '.jade'
   encoding: 'utf8'
   content: """
            doctype
            html
               head
                  title test continuum.js
               body
                  p test
                  footer
            """


# *** LESS ***
exports['styles/less/test'] = 
   extension: '.less'
   encoding: 'utf8'
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
   encoding: 'utf8'
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
   encoding: 'utf8'
   content: """
            .message
               border: 1px solid #ccc
               padding: 10px
               color: #333

            .success
               @extend .message
               borderColor: green

            .error
               @extend .message
               border-color: red

            .warning
               @extend .message
               border-color: yellow
            """

exports['styles/sass/test_scss'] =
   extension: '.scss'
   encoding: 'utf8'
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

exports['styles/sass/test_compass'] =
   extension: '.sass'
   encoding: 'utf8'
   content: """
            @import compass
            .example
               width: 48%
               margin-right: 2%
               float: left
               +clearfix
               p
                  padding-top: 10px 
            #linear-gradient
               +background-image(linear-gradient(to bottom right, white, #dddddd))
            """

# *** CSS ***
exports['styles/test'] =
   extension: '.css'
   encoding: 'utf8'
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
   encoding: 'utf8'
   content: """
            this is a non compilable test file.
            """
