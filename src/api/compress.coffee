# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: compress
# Created: 18/09/2014 11:24

fs = require 'fs'
path = require 'path'
_ = require 'lodash'
_.mixin require('underscore.string').exports()

uglify = require 'uglify-js'
csswring = require('csswring').wring
imagemin = require 'imagemin'
source_map = require './source_map.js'

###
   @param input {object}: 
      file {string}: input file path (will be used to select the appropriate compiler).
      code [string]: raw code (compiles the code without reading file from file sytem).
      source_map [object]: if defined compilation will try to generate a Mozilla V3 source map (not available for all compilers).
         file [string]: output file path (absolute or relative to source map file).
         sourceRoot [string]: root path prepended to source paths.
         sources {array}: an array of source paths involved in mapping. 
      options [object]: additional compiler configurations. 
   @param back {function}: asynchronous callback function.
   @return output {object}:
      code {string}: compiled string code.
      source_map {object}: source map if required, null otherwise.
      warnings {array}: compilation warnings.
###

exports['javascript'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      input.code = input.code or fs.readFileSync input.file, 'utf-8'
      
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = [] 
      
      # parse code.
      ast = uglify.parse input.code
      
      # compress code.
      ast.figure_out_scope()
      compressor = uglify.Compressor warnings: false
      ast = ast.transform compressor
      
      # mangle names.
      ast.figure_out_scope()
      ast.compute_char_frequency()
      ast.mangle_names()
      
      # generate compressed code.
      options = {}
      if _.isObject input.source_map
         options.source_map = uglify.SourceMap
            file: input.source_map.file or ''
            root: input.source_map.sourceRoot or ''
            # if a source map is present map back to source file.
            orig: input.source_map if _.has input.source_map, 'mappings'
      
      stream = uglify.OutputStream options
      ast.print stream
      
      output.code = stream.toString()
      
      if _.isObject input.source_map
         output.source_map = JSON.parse options.source_map.toString()
         output.source_map.sources = input.source_map.sources or []
      
      return back null, output
   
   catch err then return back err



exports['stylesheet'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      input.code = input.code or fs.readFileSync input.file, 'utf-8'
      
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      options = {}
      options.preserveHacks = true
      options.removeAllComments = true
      
      if _.isObject input.source_map
         options.map = {}
         options.map.annotation = false
         if _.has input.source_map, 'mappings'
            options.map.prev = input.source_map
      
      result = csswring input.code, options
      
      output.code = result.css
      if _.isObject input.source_map
         output.source_map = JSON.parse result.map.toString()
         output.source_map.file = input.source_map.file or ''
         output.source_map.sources = input.source_map.sources or []
         output.source_map.sourceRoot = input.source_map.sourceRoot or ''
      
      return back null, output


   catch err then return back err


exports['image'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   try
      
      # read input code.
      input.extension = path.extname(input.file).toLowerCase().replace '.', ''
      input.code = fs.readFileSync input.file, 'base64' if _.isEmpty input.code
      
      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # prepare compression options.
      batch = new imagemin()
      batch.src(new Buffer(input.code, 'base64'))
      if input.extension is 'png' then batch.use imagemin.pngquant()
      if input.extension is 'gif' then batch.use imagemin.gifsicle(interlaced: false)
      if input.extension is 'jpg' or input.extension is 'jpeg' then batch.use imagemin.jpegtran(progressive: true)
      if input.extension is 'svg' then batch.use imagemin.svgo()
      
      # compress code.
      batch.run (err, compressed)->
         if err then return back err
         
         # return output.
         output.code = new Buffer(compressed[0].contents).toString 'base64'
         return back null, output
   
   catch err then return back err


# extension mappings.
exports['js'] = @['javascript']
exports['css'] = @['stylesheet']
exports['png'] = @['image']
exports['gif'] = @['image']
exports['jpg'] = @['image']
exports['jpeg'] = @['image']
exports['svg'] = @['image']
