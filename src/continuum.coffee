# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: index
# Created: 20/07/14 14.09


fs = require 'fs'
fs_tools = require 'fs-tools'
path = require 'path'
string = require 'string'
async = require 'async' 
_ = require 'lodash'
strip_comments = require 'strip-comments'
api = require './api.js'
log4js = require 'log4js'
log4js.getBufferedLogger = (category)->
   base_logger = log4js.getLogger category
   logger = {}
   logger.temp = []
   logger.base_logger = base_logger
   logger.flush = ->
      i = 0
      for log in logger.temp
         logger.base_logger[log.level] log.message
         delete logger.temp[i]
         i++
   logger.trace = (message)-> logger.temp.push level: 'trace', message: message
   logger.debug = (message)-> logger.temp.push level: 'debug', message: message
   logger.info = (message)-> logger.temp.push level: 'info', message: message
   logger.warn = (message)-> logger.temp.push level: 'warn', message: message
   logger.error = (message)-> logger.temp.push level: 'error', message: message
   logger.fatal = (message)-> logger.temp.push level: 'fatal', message: message
   return logger


exports['info'] = ->
   info = require './../package.json'
   name: info.name
   version: info.version
   author: info.author
   description: info.description
   license: info.license
   repository: info.repository.url 
   bugs: info.bugs.url


config = null
exports['setup'] = (options)->
   
   try # load continuum config.
      config = fs.readFileSync __dirname + '\\continuum.json', 'utf-8'
      config = strip_comments config
      config = JSON.parse config
   catch err then throw new Error __dirname + '\\continuum.json: ' + err
   
   try # merge defaults with (eventually) user config.
      user_dir = path.resolve process.cwd()
      if fs.existsSync(user_dir + '\\continuum.json')
         user_config = fs.readFileSync user_dir + '\\continuum.json', 'utf-8'
         user_config = strip_comments user_config
         user_config = JSON.parse user_config
         config = _.merge config, user_config
   catch err then throw new Error user_dir + '\\continuum.json: ' + err
   
   # merge config with (eventually) provided options.
   config = _.merge config, (options or {})

   # merge config with (eventually) command line arguments.
   commander = require 'commander'
   commander.version @.info().version
   commander.usage '[options]'
   commander.option '-i, --input <dir>', 'defines input directory for batching files.'
   commander.option '-o, --output <dir>', 'defines output directory for batched files.'
   commander.option '-t, --transformation', 'enables continuos passing style callbacks transformation.'
   commander.option '-s, --source_map [dir]', 'enables source maps generation and optionally defines directory.'
   commander.option '-c, --cache [dir]', 'enables files caching and optionally defines directory.'
   commander.option '-l, --log [dir]', 'enables logging and optionally defines directory.'
   commander.parse process.argv
   if commander.input
      config.input.path = if _.isString commander.input then commander.input else config.input.path
   if commander.output
      config.output.path = if _.isString commander.output then commander.output else config.output.path
   if commander.cache
      config.cache.enabled = true
      config.cache.path = if _.isString commander.cache then commander.cache else config.cache.path
   if commander.source_map
      config.source_map.enabled = true
      config.source_map.path = if _.isString commander.source_map then commander.source_map else config.source_map.path
   if commander.log
      config.log.enabled = true
      config.log.path = if _.isString commander.log then commander.log else config.log.path
   if commander.transformation is true then config.transformation.enabled = true
   
   # setup configurations.
   # input.
   config.input.path = './' if config.input.path is '.'
   config.input.path = path.normalize config.input.path
   config.input.info = fs.lstatSync config.input.path
   
   # output.
   config.output.path = './' if config.output.path is '.'
   config.output.path = if config.output.path then path.normalize config.output.path else config.input.path
   if not fs.existsSync config.output.path then fs_tools.mkdirSync config.output.path
   config.output.info = fs.lstatSync config.output.path
   if config.output.info.isFile() then throw new Error 'output must be a directory.'
   
   # cache.
   if config.cache.enabled is true
      config.cache.path = './' if config.cache.path is '.'
      config.cache.path = if config.cache.path then path.normalize config.cache.path else config.input.path
      if not fs.existsSync config.cache.path then fs_tools.mkdirSync config.cache.path
      config.cache.info = fs.lstatSync config.cache.path
      if config.cache.info.isFile() then throw new Error 'cache must be a directory'
   
   # source maps.
   if config.source_map.enabled is true
      config.source_map.path = './' if config.source_map.path is '.'
      config.source_map.path = if config.source_map.path then path.normalize config.source_map.path else config.input.path
      if not fs.existsSync config.source_map.path then fs_tools.mkdirSync config.source_map.path
      config.source_map.info = fs.lstatSync config.source_map.path
      if config.source_map.info.isFile() then throw new Error 'source_map must be a directory.'
   
   # logs.
   if config.log.enabled is true
      appenders = []
      
      if config.log.levels.file.toLocaleUpperCase() isnt 'OFF'
         config.log.path = './' if config.log.path is '.'
         config.log.path = if config.log.path then path.normalize config.log.path else config.input.path
         if not fs.existsSync config.log.path then fs_tools.mkdirSync config.log.path
         appenders.push
            type: 'logLevelFilter'
            level: config.log.levels.file
            appender:
               type: 'file', filename: config.log.path + '\\' + config.log.name + '.' + config.log.extension
               layout: type: 'pattern', pattern: '[%d{yyyy-MM-dd hh:mm}] [%p] - %m'
      
      appenders.push
         type: 'logLevelFilter'
         level: config.log.levels.console
         appender:
            type: 'console'
            layout: type: 'pattern', pattern: '%[[%p]%] %m'
      log4js.configure appenders: appenders
   
   else log4js.setGlobalLogLevel 'OFF'
   
   return config


exports['run'] = (options, back)->
   try
      
      # setup runtime with provided options.
      if _.isFunction options then back = options; options = {}
      config = @.setup options
      logger = log4js.getLogger ' '
      
      # stats.
      batch = {}
      batch.directory = path.resolve process.cwd()
      batch.processed = 0
      batch.skipped = 0
      batch.failures = 0
      batch.successes = 0
      batch.started = Date.now()
      
      # walk through input and compile.
      logger.info '*** processing project: starting... ***'
      logger.debug '[input: ' + config.input.path + ', output: ' + config.output.path + ']\n'
      fs_tools.walk config.input.path, (input_file, input_info, next)->
         
         input = {}
         input.extension = path.extname(input_file).replace '.', ''
         input.file = input_file
         input.directory = path.dirname input.file
         input.find_compiler = -> _.find config.compilation.compilers, (compiler)->
            if _.isArray compiler.input_extension then _.contains compiler.input_extension, input.extension
            else compiler.input_extension is input.extension
         input.code = ''
         
         output = {}
         output.extension = input.find_compiler()?.output_extension ? input.extension
         output.file = input.file.replace(config.input.path, config.output.path).replace '.' + input.extension, '.' + output.extension
         output.directory = config.output.path + '\\' + path.dirname path.relative(config.output.path, output.file) 
         output.is_js = -> input.extension is 'js' or input.find_compiler()?.output_extension is 'js' 
         output.code = ''

         source_map = {}
         source_map.is_enabled = -> config.source_map.enabled is true
         source_map.extension = config.source_map.extension
         source_map.file = input.file.replace(config.input.path, config.source_map.path).replace '.' + input.extension, '.' + source_map.extension
         source_map.directory = config.source_map.path + '\\' + path.dirname path.relative(config.source_map.path, source_map.file)
         source_map.link = '/*# sourceMappingURL=' + path.relative(output.directory, source_map.directory) + '\\' + path.basename(source_map.file) + ' */'
         source_map.code = if source_map.is_enabled() then file: path.resolve(output.file), sources: [path.relative(source_map.directory, input.file)] else undefined
         
         cache = {}
         cache.is_enabled = -> config.cache.enabled is true
         cache.extension = config.cache.extension
         cache.file = input.file.replace(config.input.path, config.cache.path).replace '.' + input.extension, '.' + cache.extension
         cache.directory = config.cache.path + '\\' + path.dirname path.relative(config.cache.path, cache.file)
         cache.exists = -> fs.existsSync(cache.file) and (input_info.mtime <= fs.lstatSync(cache.file).mtime)
         cache.code = ''
         
         # skip output, cache, source_map and log directories.
         if config.input.path isnt config.output.path and string(input.directory).contains(config.output.path) then return next()
         if config.input.path isnt config.cache.path and string(input.directory).contains(config.cache.path) then return next()
         if config.input.path isnt config.source_map.path and string(input.directory).contains(config.source_map.path) then return next()
         if config.input.path isnt config.log.path and string(input.directory).contains(config.log.path) then return next()
         if input.file is config.log.name + config.log.extension then return next()
         
         # count processed files.
         batch.processed++
         
         # if enabled, read from cache and skip if source file is not changed.
         if cache.is_enabled() and cache.exists() then batch.skipped++; return next()
         
         # start processing input file.
         log = log4js.getBufferedLogger ' '
         log.info 'processing file: ' + input.file
         failed = false
         async.series [
            
            # read input file.
            (back)-> fs.readFile input.file, 'utf-8', (err, result)->
               if err
                  failed = true
                  log.error err.message
                  log.trace err.stack
                  log.error 'reading input: FAILED!'
               else input.code = result
               output.code = input.code
               return back()
            
            
            # code normalization.
            (back)->
               # skip if interrupted. 
               if failed is true then return back()
               
               # replace cps callback marker with a compilation safer one
               # or stop processing if marker is detected and transformation is disabled. 
               if output.is_js() 
                  if config.transformation.enabled is false and
                  (string(output.code).contains config.transformation.lazy_marker or string(output.code).contains config.transformation.strict_marker)
                     failed = true
                     log.error 'callback markers detected but transformation is disabled.'
                  else
                     output.code = string(output.code)
                     .replaceAll config.transformation.strict_marker, config.transformation.strict_safe_marker
                     .replaceAll config.transformation.lazy_marker, config.transformation.lazy_safe_marker
                     .toString()
               
               return back()
            
            
            # perform compilation.
            (back)-> 
               # skip if interrupted. 
               if failed is true then return back()
               # skip if not enabled.
               if config.compilation.enabled isnt true then return back()
               # skip non compilable files.
               if not _.has api.compile, input.extension then return back()
                
               api.compile[input.extension]
                  file: input.file
                  code: output.code
                  source_map: if source_map.is_enabled() then source_map.code else null
                  options: input.find_compiler()?.options or {}
               , (err, result)->
                  if err
                     failed = true
                     log.error err.message
                     log.trace err.stack
                     log.error 'compilation: FAILED!'
                  else 
                     output.code = result.code
                     source_map.code = result.source_map
                     log.warn warn for warn in result.warnings
                     log.debug 'compilation: done! [warnings: ' + result.warnings.length + ']'
                  return back()
            
            
            # perform cps transformation.
            (back)->
               # skip if interrupted. 
               if failed is true then return back()
               # skip if not enabled.
               if config.transformation.enabled is false then return back()
               # skip non transformable files.
               if not output.is_js() then return back()
               # skip if cps markers are not finded in code.
               if not (string(output.code).contains config.transformation.lazy_safe_marker or string(output.code).contains config.transformation.strict_safe_marker) then return back()
               
               api.transform.cps 
                  file: output.file 
                  code: output.code
                  source_map: if source_map.is_enabled() then source_map.code else null
                  options:
                     lazy_marker: config.transformation.lazy_safe_marker
                     strict_marker: config.transformation.strict_safe_marker
               , (err, result)->
                  if err 
                     failed = true
                     log.error err.message
                     log.trace err.stack
                     log.error 'cps transformation: FAILED!'
                  else
                     output.code = result.code
                     source_map.code = result.source_map
                     log.debug 'cps transformation: done!'
                  return back()
            
            
            # perform code analysis.
            (back)->
               # skip if interrupted. 
               if failed is true then return back()
               # skip if not enabled.
               if config.analysis.enabled isnt true then return back()
               # skip non analizable files.
               if not _.has api.analize, output.extension then return back()
               
               api.analize[output.extension]
                  file: output.file
                  source: input.code
                  code: output.code
                  source_map: if source_map.is_enabled() then source_map.code else null
                  options: config.analysis[output.extension] or {}
               , (err, warnings)->
                  if err
                     log.error err.message 
                     log.trace err.stack
                     log.error 'code analysis: FAILED!'
                  else
                     # output source mapped warnings first.
                     warnings = _.sortBy warnings, (warning)-> warning.source_mapped is false
                     for warning in warnings
                        type = if warning.source_mapped is true then 'S' else 'C'
                        log.warn warning.message + ' - ' + type + '[' + warning.line + ', ' + warning.column + ']: ' + warning.code
                     legend = if warnings.length isnt 0 then 'S: source, C: compiled' else ''
                     log.debug 'code analysis: done! [warnings: ' + warnings.length + '] ' + legend
                  return back()
            
            
            # write output file.
            (back)->
               # skip if process is interrupted.
               if failed is true then return back()
               
               # add source map reference to output if required.
               if source_map.is_enabled() then output.code += '\n' + source_map.link
               
               async.series [
                  (back)-> fs_tools.mkdir output.directory, back
                  (back)-> fs.writeFile output.file, output.code, back
               ], (err)->
                  if err
                     failed = true
                     log.error err.message
                     log.trace err.stack
                     log.error 'writing output file: FAILED!'
                  return back()
            
            
            # write source map.
            (back)->
               # skip if process is interrupted.
               if failed is true then return back()
               # skip if source map is not enabled.
               if not source_map.is_enabled() then return back()
               # skip if source map is not present.
               if not _.has source_map.code, 'mappings' then return back()
               
               # stringify and write source maps. 
               source_map.code = JSON.stringify source_map.code, null, 4
               async.series [
                  (back)-> fs_tools.mkdir source_map.directory, back
                  (back)-> fs.writeFile source_map.file, source_map.code, back
               ], (err)->
                  if err
                     failed = failed # do not stop processing.
                     log.error err.message
                     log.trace err.stack
                     log.warn 'source mapping: FAILED!'
                  else log.debug 'source mapping: done!'
                  return back()
            
            
            # write cache file.
            (back)->
               # skip if process is interrupted.
               if failed is true then return back()
               # skip if not enabled.
               if not cache.is_enabled() then return back()
               
               async.series [
                  (back)-> fs_tools.mkdir cache.directory, back
                  (back)-> fs.writeFile cache.file, cache.code, back
               ], (err)->
                  if err
                     failed = failed # do not stop processing.
                     log.error err.message
                     log.trace err.stack
                     log.warn 'caching: FAILED!' 
                  return back()
            
            
            # log end processinging file.
            (back)->
               if failed is true
                  batch.failures++
                  log.error 'processing file: FAILED!\n'
               else
                  batch.successes++
                  log.info 'processing file: done!\n'
               log.flush()
               batch.ended = Date.now()
               batch.duration = ((batch.ended - batch.started) / 1000) + 's'
               return back()
         
         ], next
      
      , -> # (end of input walk, errors are self printed by each file).
         logger.info '*** processing project: done! ***'
         logger.debug '[duration: ' + batch.duration + ', processed: ' + batch.processed + ', skipped: ' + batch.skipped + ', successes: ' + batch.successes + ', failures: ' + batch.failures + ']'

         if back then back null,
            processed: batch.processed
            skipped: batch.skipped
            successes: batch.successes
            failures: batch.failures
   
   catch err 
      if back then back err else console.error err
