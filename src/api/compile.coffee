# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: compile
# Created: 18/09/2014 10:12

fs = require 'fs'
_ = require 'lodash'
_.mixin require('underscore.string').exports()

coffeescript = require 'coffee-script'
livescript = require 'LiveScript'
sass = require 'node-sass'
stylus = require 'stylus'
less = require 'less'
jade = require 'jade'


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


exports['coffeescript'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code

      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # prepare compiler options.
      options = {}
      options.filename = input.file
      options = _.merge options, (input.options or {})
      if _.isObject input.source_map
         options.sourceMap = true
         options.sourceRoot = input.source_map.sourceRoot or ''
         options.sourceFiles = input.source_map.sources or []
         options.generatedFile = input.source_map.file or ''
      
      # compile code.
      compiled = coffeescript.compile input.code, options
      
      # return output.
      output.code = compiled.js or compiled
      output.source_map = JSON.parse compiled.v3SourceMap if compiled.v3SourceMap
      output.warnings = []
      return back null, output
   
   catch err then return back err


exports['livescript'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code
      
      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # compile code 
      compiled = livescript.compile input.code #, input.options #@todo: pass livescript options.
      
      # return output.
      output.code = compiled
      output.warnings.push 'livescript doesn\'t support source maps.' if _.isObject input.source_map
      return back null, output
   
   catch err then return back err


exports['sass'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code
      
      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # prepare compilation options.
      options = {}
      options.file = input.file
      options.data = input.code
      options = _.merge options, (input.options or {})
      if _.isObject input.source_map
         options.sourceComments = 'map'
         options.sourceMap = '.' # bugfix: use fake path and replace later.
         options.outFile = '.'
      
      options.error = (err)-> return back new Error(err.replace(options.file + ':', '').replace('\n', ''))
      
      options.success = (compiled, map)->
         try
            output.code = compiled
            if _.isObject input.source_map
               # (problems with wrong paths in source_map. can't parse cause '\' instead of '\\'. 
               # extract mapping and recreate object).
               mappings = _.strRight(map, '"mappings":')
               mappings = _.trim(mappings).replace(/\}/g, '').replace(/\n/g, '').replace(/"/g, '')
               output.source_map =
                  version: 3
                  file: input.source_map.file or ''
                  sourceRoot: input.source_map.sourceRoot or ''
                  sources: input.source_map.sources or []
                  names: []
                  mappings: mappings
            return back null, output
         catch err then return back err
      
      # compile code.
      sass.render options 
   
   catch err then return back err


exports['less'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code
      
      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # prepare compilation options.
      options = {}
      options = _.merge options, (input.options or {})
      if _.isObject input.source_map
         options.sourceMap = true
         
         # return source map.
         options.writeSourceMap = (map)-> 
            output.source_map = JSON.parse map
            output.source_map.sourceRoot = input.source_map.sourceRoot or ''
            output.source_map.sources = input.source_map.sources or []
            output.source_map.file = input.source_map.file or ''
      
      # compile code.
      less.render input.code, options, (err, compiled)->
         if err then return back err
         
         # return output.
         output.code = compiled
         return back null, output
   
   catch err then return back err


exports['stylus'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code
      
      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # prepare compilation options.
      stylus = stylus input.code
      stylus.set 'filename', input.file
      stylus.set 'options', input.options or {}
      stylus.set 'sourcemap', comment: false
      
      # compile code.
      stylus.render (err, compiled)->
         if err then return back err
         
         # return output.
         output.code = compiled
         output.source_map = stylus.sourcemap
         output.source_map.file = input.source_map.file or ''
         output.source_map.sourceRoot = input.source_map.sourceRoot or ''
         output.source_map.sources = input.source_map.sources or []
         return back null, output

   catch err then return back err


exports['jade'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code
      
      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # compile code.
      jade.render input.code, (input.options or {}), (err, compiled)->
         if err then return back err
         
         # return output.
         output.code = compiled
         return back null, output
   
   catch err then return back err  


# extension mappings.
exports['litcoffee'] = @['coffeescript']
exports['coffee'] = @['coffeescript']
exports['ls'] = @['livescript']
exports['scss'] = @['sass']
exports['styl'] = @['stylus']