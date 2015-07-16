# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: doc
# Created: 05/07/2015 18:44

async = require 'async'
_ = require 'lodash'
_.string = require 'underscore.string'
_.mixin _.string.exports()
jschema = require('jjv')
jschema = jschema()
coffeeson = require 'coffeeson'

exports['schema'] =
   $schema: 'http://json-schema.org/schema#'
   type: 'object'
   properties:
      'name': type: 'string'
      'description': type: 'string'
      'author': anyOf: type: 'string', type: 'array', type: 'object'
      'type': type: 'string', enum: ['function', 'class', 'property', 'object']
      'async': type: 'boolean'
      'arguments': type: 'object'
      'returns': $schema: 'http://json-schema.org/schema#'
   
   additionalProperties: false
   required: ['name', 'arguments', 'returns']


exports['run'] = (input, log, back)->
   self = @
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')
   try
      
      # read input code.
      input.code = fs.readFileSync input.file, 'utf8' if _.isEmpty input.code
      
      # prepare output.
      output = {}
      output.code = null
      output.warnings = []
      
      # extract documentation from code.
      input.code = input.code.toString().match /\/\*@doc[^\/\*]*\*\//igm

      # skip if not founded.
      if input.code is null or input.code.length is 0 then return back null, output
      
      # compile each portion with coffee.
      output.code = []
      async.each input.code, (chunk, next)->
         chunk = chunk.replace(/\/\*@doc/igm, '').replace(/\*\//igm, '')
         chunk = chunk.replace key, key.replace('@','') for key in chunk.match /@\w+:/igm
         chunk = coffeeson.parse chunk
         errors = jschema.validate self.schema, chunk
         if errors is null then output.code.push chunk
         else
            log.warn 'member "' + chunk.name + '" has some errors:' 
            log.warn '   @' + key + ': ' + JSON.stringify errors.validation[key] for key in _.keys errors.validation 
         return next()
         
      , -> return back null, output

   catch err then return back err
      