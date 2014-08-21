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
   
   # load continuum config.
   config = require './continuum.json'
   
   # merge defaults with (eventually) user config.
   if fs.existsSync(__dirname + 'continuum.json') then config = _.merge config, require(__dirname + 'continuum.json')
   
   # merge config with (eventually) provided options.
   config = _.merge config, (options or {})

   # merge config with (eventually) command line arguments.
   commander = require 'commander'
   commander.version @.info().version
   commander.usage '[options]'
   commander.option '-i, --input <dir>', 'defines input directory for processing files.'
   commander.option '-o, --output <dir>', 'defines output directory for processed files.'
   commander.option '-t, --transformation', 'enables continuos passing style callbacks transformation.'
   commander.option '-e, --explicit', 'produces callbacks transformation only if "use cps" is explicitly declared at the beginning of file.'
   commander.option '-s, --source_map [dir]', 'enables source maps generation and optionally defines directory.'
   commander.option '-c, --cache [dir]', 'enables files caching and optionally defines directory.'
   commander.option '-l, --log [dir]', 'enables logging and optionally defines directory.'
   commander.parse process.argv
   if commander.input
      config.input.path = if typeof commander.input is 'string' then commander.input else config.input.path
   if commander.output
      config.output.path = if typeof commander.output is 'string' then commander.output else config.output.path
   if commander.cache
      config.cache.enabled = true
      config.cache.path = if typeof commander.cache is 'string' then commander.cache else config.cache.path
   if commander.source_map
      config.source_map.enabled = true
      config.source_map.path = if typeof commander.source_map is 'string' then commander.source_map else config.source_map.path
   if commander.log
      config.log.enabled = true
      config.log.path = if typeof commander.log is 'string' then commander.log else config.log.path
   if commander.transformation is true then config.transformation.enabled = true
   if commander.explicit is true then config.transformation.explicit = true

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
   if config.output.info.isFile() then throw 'output must be a directory.'
   # cache.
   config.cache.path = './' if config.cache.path is '.'
   config.cache.path = if config.cache.path then path.normalize config.cache.path else config.input.path
   if not fs.existsSync config.cache.path then fs_tools.mkdirSync config.cache.path
   config.cache.info = fs.lstatSync config.cache.path
   if config.cache.info.isFile() then throw 'cache must be a directory'
   # source maps.
   config.source_map.path = './' if config.source_map.path is '.'
   config.source_map.path = if config.source_map.path then path.normalize config.source_map.path else config.input.path
   if not fs.existsSync config.source_map.path then fs_tools.mkdirSync config.source_map.path
   config.source_map.info = fs.lstatSync config.source_map.path
   if config.source_map.info.isFile() then throw 'source_map must be a directory.'
   # logs.
   if config.log.enabled is false
      config.log.levels.console = 'OFF'
      config.log.levels.file = 'OFF'
   config.log.path = './' if config.log.path is '.'
   config.log.path = if config.log.path then path.normalize config.log.path else config.input.path
   if not fs.existsSync config.log.path then fs_tools.mkdirSync config.log.path
   
   # configure logger.
   appenders = []
   appenders.push
      type: 'logLevelFilter'
      level: config.log.levels.console
      appender: 
         type: 'console'
         layout: type: 'pattern', pattern: '%[[%p]%] %m'
   appenders.push
      type: 'logLevelFilter'
      level: config.log.levels.file
      appender:
         type: 'file', filename: config.log.path + '\\' + config.log.name + config.log.extension
         layout: type: 'pattern', pattern: '[%d{yyyy-MM-dd hh:mm}] [%p] - %m'
   log4js.configure appenders: appenders
   
   return config


exports['run'] = (options, back)->
   try
      
      # setup runtime with provided options.
      if _.isFunction options then back = options; options = {}
      config = @.setup options
      logger = log4js.getLogger ' '
      
      # stats.
      process = {}
      process.processed = 0
      process.skipped = 0
      process.failures = 0
      process.successes = 0

      # walk through input and compile.
      logger.info '*** processing project: starting... ***'
      logger.debug '[input: ' + config.input.path + ', output: ' + config.output.path + ']\n'
      fs_tools.walk config.input.path, (input_file, input_info, next)->
         
         input = {}
         input.file = input_file
         input.extension = path.extname(input_file).replace '.', ''
         input.directory = path.dirname input_file
         input.find_compiler = -> _.find config.compilation.compilers, (compiler)->
            if _.isArray compiler.input_extension then _.contains compiler.input_extension, input.extension
            else compiler.input_extension is input.extension
         input.is_js = -> input.extension is 'js'
         input.is_css = -> input.extension is 'css' 
         input.is_html = -> input.extension is 'html' or input.extension is 'htm'
         input.is_unknown = -> not input.find_compiler()?
         
         output = {}
         output.extension = input.find_compiler()?.output_extension ? input.extension
         output.file = input.file.replace(config.input.path, config.output.path).replace '.' + input.extension, '.' + output.extension
         output.directory = config.output.path + '\\' + path.dirname path.relative(config.output.path, output.file) 
         output.is_js = -> input.is_js() or input.find_compiler()?.output_extension is 'js'
         output.is_css = -> input.is_css() or input.find_compiler()?.output_extension is 'css'
         output.is_html = -> input.is_html() or input.find_compiler()?.output_extension is 'html' 
         output.options = input.find_compiler()?.options ? {}
         output.code = ''
         output.source_map = '' 
         
         cache = {}
         cache.file = input.file.replace(config.input.path, config.cache.path).replace('.' + input.extension, config.cache.extension)
         cache.directory = path.dirname path.relative(config.cache.path, cache.file)
         
         # skip output, cache, source_map and log directories.
         if config.input.path isnt config.output.path and string(input.directory).contains(config.output.path) then return next()
         if config.input.path isnt config.cache.path and string(input.directory).contains(config.cache.path) then return next()
         if config.input.path isnt config.source_map.path and string(input.directory).contains(config.source_map.path) then return next()
         if config.input.path isnt config.log.path and string(input.directory).contains(config.log.path) then return next()
         if input.file is config.log.name + config.log.extension then return next()
         
         # count processed files.
         process.processed++
         
         # if enabled, read from cache and skip if source file is not changed.
         if config.cache.enabled is true and fs.existsSync(cache.file) and (input_info.mtime <= fs.lstatSync(cache.file).mtime)
            process.skipped++
            return next()
         
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
               else output.code = result
               return back()
            
            
            # if output is javascript replace callback marker with a compilation safer one.
            # (do it before compilation cause the marker should interfeer with compilation).
            (back)->
               if config.transformation.enabled is true and output.is_js()
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
               if config.compilation.enabled is false then return back()
               # skip non compilable files.
               if input.is_unknown() or input.is_js() or input.is_css() or input.is_html() then return back()
               
               api.compile input.file, output.code, output.options, (err, compiled)->
                  if err
                     failed = true
                     # (coffee-script need the stack to show the error line).
                     if input.extension is 'coffee' then log.error err.stack else log.error err.message
                     log.trace err.stack
                     log.error 'compilation: FAILED!'
                  else 
                     output.code = compiled.code 
                     output.source_map = compiled.source_map
                     log.debug 'compilation: done!'
                  return back()
            
            
            # perform cps transformation.
            (back)->
               # skip if interrupted. 
               if failed is true then return back()
               # skip if not enabled.
               if config.transformation.enabled is false then return back()
               # skip non transformable files.
               if not output.is_js() then return back()
               # skip if explicit is required and no 'use cps' is declared in file.
               if config.transformation.explicit is true and not string(output.code).contains config.transformation.explicit_token then return back()
               
               api.transform input.file, output.code, output.source_map, 
               lazy_marker: config.transformation.lazy_safe_marker
               strict_marker: config.transformation.strict_safe_marker,
               (err, transformed)->
                  if err 
                     failed = true
                     log.error err.message
                     log.trace err.stack
                     log.error 'cps transformation: FAILED!'
                  else
                     output.code = transformed.code
                     output.source_map = transformed.source_map
                     log.debug 'cps transformation: done!'
                  return back()
            
            
            # perform code analysis.
            (back)->
               # skip if interrupted. 
               if failed is true then return back()
               # skip if not enabled.
               if config.analysis.enabled isnt true then return back()
               # skip non analizable files.
               if not (output.is_js() or output.is_css() or output.is_html()) then return back()
               api.analize output.file, output.code, config.analysis[output.extension]?.options, (err, result)->
                  if err
                     log.error err.message 
                     log.trace err.stack
                     log.error 'code analysis: FAILED!'
                  else
                     for warn in result then log.warn warn.message + ' - [' + warn.line + ', ' + warn.column + ']: ' + warn.evidence
                     log.debug 'code analysis: done! [warnings: ' + result.length + ']'
                  return back()
            
            
            # write output file.
            (back)->
               # skip if process is interrupted.
               if failed is true then return back()
               async.series [
                  (back)-> fs_tools.mkdir output.directory, back
                  (back)-> fs.writeFile output.file, output.code, back
               ], (err)->
                  if err
                     failed = true
                     log.error err.message
                     log.trace err.stack
                     log.error 'writing output: FAILED!'
                  return back()
            
            
            # write cache file.
            (back)->
               # skip if process is interrupted.
               if failed is true then return back()
               # skip if not enabled.
               if config.cache.enabled isnt true then return back()
               async.series [
                  (back)-> fs_tools.mkdir config.cache.path + '\\' + cache.directory, back
                  (back)-> fs.writeFile cache.file, '', back
               ], (err)->
                  if err
                     log.error err.message
                     log.trace err.stack
                     log.warn 'caching: FAILED!' 
                  return back()
            
            
            # log end processing file.
            (back)->
               if failed is true
                  process.failures++
                  log.error 'processing file: FAILED!\n'
               else
                  process.successes++
                  log.info 'processing file: done!\n'
               
               log.flush()
               return back()
         
         ], next
      
      , -> # (end of input walk, errors are self printed by each file).
         logger.info '*** processing project: done! ***'
         logger.debug '[processed: ' + process.processed + ', skipped: ' + process.skipped + ', successes: ' + process.successes + ', failures: ' + process.failures + ']'

         if back then back null, 
            processed: process.processed
            skipped: process.skipped
            successes: process.successes
            failures: process.failures
   
   catch err 
      if back then back err else return throw err
