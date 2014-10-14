# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: compile
# Created: 18/09/2014 10:12

fs = require 'fs'
path = require 'path'
exec = require('child_process').execFile
async = require 'async'
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
      config [object]: additional compiler configurations. 
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
      options = _.merge options, (input.config.options or {})
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
      compiled = livescript.compile input.code #, input.config.options #@todo: pass livescript options.
      
      # return output.
      output.code = compiled
      output.warnings.push 'livescript doesn\'t support source maps.' if _.isObject input.source_map
      return back null, output
   
   catch err then return back err

#@todo: do not compile partial files (ex: _base.sass)
exports['compass'] = (input, back)->
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

      options = {}
      options.cwd = path.resolve process.cwd()
      
      COMPASS_CMD = 'compass.bat'
      COMPASS_CONFIG = options.cwd + '\\' + 'compass.rb'
      COMPASS_ERR_MISSING = 'You need to have Ruby and Compass installed and in your system PATH for compilation to work.'
      
      async.series [
         
         # create compass configuration file.
         (back)->
            
            # skip if file exists.
            if fs.existsSync COMPASS_CONFIG then return back() 
            
            # cleanup user configurations.
            config = input.config.compass.options
            ignore = ['sass_dir', 'sass_path', 'css_dir', 'css_path', 'sourcemap']
            delete config[key] for key in _.keys config when _.include ignore, key
            
            # create configuration file.
            content = """
            # generated by continuum.js, use continuum.json to setup your compass configurations. 
            # compass reference: http://compass-style.org/help/documentation/configuration-reference/
            # these properties will be ignored for compiler to work:
            # [#{ ignore.join ', ' }].\n
            require 'compass/import-once/activate'\n
            """
            content += "require '" + library + "'\n" for library in config.require
            delete config.require
            print = (value)-> if _.isString(value) and not _.string.startsWith(value, ':') then value = "'" + value + "'" else value
            content += "\n" + key + " = " + print(config[key]) for key in _.keys config 
            
            # write configuration file.
            fs.writeFile COMPASS_CONFIG, content, back
         
         # compile to temporary directory.
         (back)->
            args = ['compile']
            args.push path.relative options.cwd, input.file
            args.push '--config=' + COMPASS_CONFIG
            args.push '--sass-dir=' + path.dirname input.file
            args.push '--css-dir=' + input.temp_path
            args.push '--sourcemap' if _.isObject input.source_map
            
            exec COMPASS_CMD, args, options, (err, out, code)->
               if err and err.code is 127 then return back new Error COMPASS_ERR_MISSING
               if err and _.string.trim err.message is 'Command failed:' then return back new Error(if not _.isEmpty(code) then code else out) 
               if err then return back err
               back()
         
         # read compiled from temporary directory.
         (back)->
            compiled = input.temp_path + '\\' + path.basename(input.file).replace(path.extname(input.file), '.css')
            fs.readFile compiled, 'utf8', (err, compiled)->
               if err then return back err
               output.code = compiled
               back()
         
         # read generated source map.
         (back)->
            # skip if source map is not required.
            if not _.isObject input.source_map then return back()
            source_map = input.temp_path + '\\' + path.basename(input.file).replace(path.extname(input.file), '.css.map')
            fs.readFile source_map, 'utf8', (err, source_map)->
               if err then return back err
               output.source_map = JSON.parse source_map
               output.source_map.file = input.source_map.file
               back()
         
      ], (err)->
         if err then return back err
         return back null, output
      
   catch err then back err


#@todo: do not compile partial files (ex: _base.sass)
exports['sass'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   if _.isObject input.source_map and not _.isArray input.source_map.sources then return back new Error 'input.source_map.sources is required {array}.'
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code
      
      # if compass is used redirect to compass compilation.
      if _.string.contains input.code, 'compass' then return @.compass input, back
      
      # prepare output.
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      # prepare compilation options.
      options = {}
      options.file = input.file
      options.data = input.code
      options = _.merge options, (input.config.options or {})
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
      options = _.merge options, (input.config.options or {})
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
      stylus.set 'options', input.config.options or {}
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
      jade.render input.code, (input.config.options or {}), (err, compiled)->
         if err then return back err
         
         # return output.
         output.code = compiled
         return back null, output
   
   catch err then return back err  


# extension mappings.
exports['coffee'] = @['coffeescript']
exports['litcoffee'] = @['coffeescript']
exports['ls'] = @['livescript']
exports['less'] = @['less']
exports['sass'] = @['sass']
exports['scss'] = @['sass']
exports['styl'] = @['stylus']
exports['stylus'] = @['stylus']
exports['jade'] = @['jade']