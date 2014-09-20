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
      
      input.code = input.code or fs.readFileSync input.file, 'utf-8'
      
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      options = {}
      options.filename = input.file
      options = _.merge options, (input.options or {})
      if _.isObject input.source_map
         options.sourceMap = true
         options.sourceRoot = input.source_map.root or ''
         options.sourceFiles = input.source_map.sources or []
         options.generatedFile = input.source_map.file or ''
      
      compiled = coffeescript.compile input.code, options
      output.code = compiled.js or compiled
      output.source_map = JSON.parse compiled.v3SourceMap if compiled.v3SourceMap
      return back null, output
   
   catch err then return back err


exports['livescript'] = (input, back)->
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
      
      if _.isObject input.source_map then output.warnings.push 'livescript doesn\'t support source maps.'
      output.code = livescript.compile input.code #, input.options #@todo: pass livescript options.
      return back null, output
   
   catch err then return back err


exports['sass'] = (input, back)->
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
      options.file = input.file
      options.data = input.code
      options = _.merge options, (input.config or {})
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
                  file: input.source_map.file
                  sourceRoot: input.source_map.root or ''
                  sources: input.source_map.sources
                  names: []
                  mappings: mappings
            return back null, output
         catch err then return back err
      
      sass.render options 
   
   catch err then return back err


exports['less'] = (input, back)->
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
      
      less.render input.code, (err, compiled)->
         if err then return back err
         output.code = compiled
         return back null, output
   
   catch err then return back err


exports['stylus'] = (input, back)->
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
      options.filename = input.file
      options.sourcemaps = _.isObject options.source_map
      options.compress = false
      options.linenos = true
      options = _.merge options, (input.config or {})

      stylus.render input.code, options, (err, compiled)->
         if err then return back err
         output.code = compiled
         return back null, output

   catch err then return back err


exports['jade'] = (input, back)->
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
      options = _.merge options, (input.config or {})
      
      jade.render input.code, options, (err, compiled)->
         if err then return back err
         output.code = compiled
         return back null, output
   
   catch err then return back err  


exports['coffee'] = @['coffeescript']
exports['ls'] = @['livescript']
exports['scss'] = @['sass']
exports['styl'] = @['stylus']