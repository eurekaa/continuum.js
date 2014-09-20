# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: compress
# Created: 18/09/2014 11:24


uglify = require 'uglifyjs'

exports['javascript'] = (input_file, input_code, options, back)->
   code = uglify.minify(code,
      fromString: true
      mangle: false
      beautify: true
   ).code