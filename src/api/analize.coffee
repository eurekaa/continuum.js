# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: analize
# Created: 18/09/2014 11:23

fs = require 'fs'
_ = require 'lodash'
_.mixin require('underscore.string').exports()

jshint = require('jshint').JSHINT
csslint = require('csslint').CSSLint
htmlint = require 'html5-lint'
source_map = require './source_map.js'


exports['javascript'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   try
      
      warnings = []
      input.code = fs.readFileSync input.file, 'utf-8' if not input.code
      result = jshint input.code, input.options
      
      if result is false
         for item in jshint.errors when item isnt null
            
            warning = {}
            warning.message = _.trim item.reason
            warning.code = _.trim item.evidence
            warning.source_mapped = false
            warning.line = item.line
            warning.column = item.character
            
            # try to translate position and code.
            if _.isObject(input.source_map) and _.has(input.source_map, 'mappings') and _.isString(input.source)
               position = source_map.get_original_position input.source_map, { source: input.source_map.sources[0], line: warning.line, column: warning.column }
               warning.source_mapped = position.line isnt null
               if warning.source_mapped is true
                  warning.line = position.line
                  warning.column = position.column
                  warning.code = _.trim _.lines(input.source)[position.line - 1]
            
            warnings.push warning
      
      return back null, warnings
   
   catch err then return back err


exports['stylesheet'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   try
      
      warnings = []
      input.code = fs.readFileSync input.file, 'utf-8' if not input.code
      result = csslint.verify input.code, input.options
      for item in result.messages when item isnt null
         
         warning = {}
         warning.message = _.trim _.strLeft(item.message, 'at line')
         warning.code = _.trim item.evidence
         warning.source_mapped = false
         warning.line = item.line
         warning.column = item.col
         
         # try to translate position and code.
         if _.isObject(input.source_map) and _.has(input.source_map, 'mappings') and _.isString(input.source)
            position = source_map.get_original_position input.source_map, { source: input.source_map.sources[0], line: warning.line, column: warning.column }
            warning.source_mapped = position.line isnt null
            if warning.source_mapped is true
               warning.line = position.line
               warning.column = position.column
               warning.code = _.trim _.lines(input.source)[position.line - 1]
            
         warnings.push warning
      
      return back null, warnings
   
   catch err then return back err


exports['hypertext'] = (input, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   try
      
      warnings = []
      input.code = fs.readFileSync input.file, 'utf-8' if not input.code
      htmlint input.code, input.options, (err, result)->
         if err then return back err
         for item in result.messages when item isnt null
            
            warning = {}
            warning.message = _.trim item.message
            warning.code = _.trim item.extract + '..'
            warning.source_mapped = false
            warning.line = item.lastLine
            warning.column = item.lastColumn
            
            # try to translate position and code.
            if _.isObject(input.source_map) and _.has(input.source_map, 'mappings') and _.isString(input.source)
               position = source_map.get_original_position input.source_map, { source: input.source_map.sources[0], line: warning.line, column: warning.column }
               warning.source_mapped = position.line isnt null
               if warning.source_mapped is true
                  warning.line = position.line
                  warning.column = position.column
                  warning.code = _.trim _.lines(input.source)[position.line - 1]
            
            warnings.push warning
         
         return back null, warnings
   
   catch err then return back err


exports['js'] = @['javascript']
exports['css'] = @['stylesheet']
exports['html'] = @['hypertext']
exports['htm'] = @['hypertext']