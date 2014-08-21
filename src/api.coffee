# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa
# File Name: api
# Created: 22/07/14 18.46

fs = require 'fs'
path = require 'path' 
string = require 'string'
_ = require 'lodash'
_.mixin require('underscore.string').exports()
string = require 'string'
async = require 'async'

# compilers.
coffeescript = require 'coffee-script'
livescript = require 'LiveScript'
sass = require 'node-sass'
stylus = require 'stylus'
less = require 'less'
jade = require 'jade'

# linters.
jshint = require('jshint').JSHINT
csslint = require('csslint').CSSLint
htmlint = require 'html5-lint'

# generators.
ast =
   parse: require('esprima').parse
   format: require('escodegen').generate
   walk: require('ast-types').visit
   types: require('ast-types').namedTypes
   create: require('ast-types').builders


exports['compile'] = (input_file, input_code, options, back)->
   try
      # compile source code.
      if _.isFunction options then back = options; options = null
      input_extension = path.extname(input_file).replace('.', '')
      result = code: null, source_map: null
      switch input_extension
         
         when 'coffee' 
            result.code = coffeescript.compile input_code
            back null, result
         
         when 'ls'
            result.code = livescript.compile input_code
            back null, result
         
         when 'sass', 'scss'
            options = _.merge options,
               file: input_file
               success: (compiled)->
                  result.code = compiled
                  return back null, result
               error: (err)->
                  err = err.replace(input_file + ':', '').replace '\n', ''
                  return back new Error(err)
            sass.render options
         
         when 'less' 
            less.render input_code, (err, compiled)->
               if err then return back err
               result.code = compiled
               back null, result
         
         when 'stylus'
            stylus.render input_code, filename: input_file, (err, compiled)->
               if err then return back err
               result.code = compiled
               back null, result
        
         when 'jade'
            jade.render input_code, options, (err, compiled)->
               if err then return back err
               result.code = compiled
               back null, result
         
         else
            result.code = input_code
            back null, result
   
   catch err then return back err


exports['analize'] = (input_file, input_code, options, back)->
   try
      if _.isFunction options then back = options; options = {}
      input_extension = path.extname(input_file).replace('.', '')
      options = options or {} #http://jshint.com/docs/options/
      warnings = []
      switch input_extension
         
         when 'js'
            result = jshint input_code, options
            if result is false
               for warn in jshint.errors then warnings.push
                  message: _.trim warn.reason
                  evidence: _.trim warn.evidence
                  line: warn.line
                  column: warn.character
            return back null, warnings
         
         when 'css'
            result = csslint.verify input_code, options
            for warn in result.messages then warnings.push 
               message: _.trim _.strLeft(warn.message, 'at line')
               evidence: _.trim warn.evidence 
               line: warn.line
               column: warn.col
            return back null, warnings
         
         when 'html', 'htm' 
            htmlint input_code, options, (err, result)->
               if err then return back err
               for warn in result.messages then warnings.push
                  message: _.trim warn.message
                  evidence: _.trim warn.extract + '..'
                  line: warn.lastLine
                  column: warn.lastColumn
               return back null, warnings
         
         else back null, []
   
   catch err then return back err, []


exports['transform'] = (input_file, code, source_map, options, back)->
   if _.isFunction source_map then back = source_map; source_map = null; options = {}
   if _.isFunction options then back = options; options = {}
   
   try
      
      # parse and analize code.
      value = {}
      value.null = ast.create.identifier 'null'
      value.err = ast.create.identifier 'err'
      callback = {}
      callback.lazy = ast.create.identifier(options.lazy_marker or '__')
      callback.strict = ast.create.identifier(options.strict_marker or '___')
      sintax = ast.parse code
      ast.walk sintax.body,
         
         # transform function declarations containing callback marker.
         visitFunction: (path)->
            callback.is_lazy = -> _.contains _.pluck(path.node.params, 'name'), callback.lazy.name
            callback.is_strict = -> _.contains _.pluck(path.node.params, 'name'), callback.strict.name
            
            if callback.is_lazy() or callback.is_strict()
            
            
               # rewrite return statement.
               # todo: find a way to not walk again.
               ast.walk path.node, visitReturnStatement: (path)->
                  path.get('argument').replace ast.create.conditionalExpression(
                     callback.lazy, # test callback existence.
                     ast.create.callExpression(callback.lazy, [value.null, path.node.argument]), # consequent.
                     path.node.argument # alternate
                  )
                  return false
                  #@.traverse path
               
               # inject try catch block.
               path.get('body').replace ast.create.blockStatement [
                  ast.create.tryStatement path.node.body, ast.create.catchClause value.err, null, ast.create.blockStatement [
                     ast.create.ifStatement(
                        callback.lazy, # test callback existence.
                        ast.create.returnStatement(ast.create.callExpression(callback.lazy, [value.err, value.null])), # then block.
                        ast.create.throwStatement(value.err) # else block.
                     )
                  ]
               ]
            @.traverse path
         
         
         # transform function calls containing callback marker.
         visitExpression: (path)->
            expression = {}
            expression.is_assigned = -> ast.types.AssignmentExpression.check path.node
            expression.call = if expression.is_assigned() then path.node.right else path.node
            expression.arguments = expression.call.arguments
            expression.is_call = -> ast.types.CallExpression.check expression.call
            callback.is_lazy = -> _.contains _.pluck(expression.arguments, 'name'), callback.lazy.name
            callback.is_strict = -> _.contains _.pluck(expression.arguments, 'name'), callback.strict.name
            
            # transform only expression calls with callback marker.
            if expression.is_call() and (callback.is_lazy() or callback.is_strict())
               expression.node = path.parent
               expression.recipient = if expression.is_assigned() then path.node.left else null
               expression.path = if expression.is_assigned() then path.get('right') else path
               expression.position = expression.node.name
               expression.parent = expression.node.parentPath.value
               callback.name = if callback.is_lazy() then callback.lazy.name else callback.strict.name
               callback.position = _.findIndex expression.arguments, (arg)-> arg.name is callback.name
               callback.marker = expression.path.get('arguments', callback.position)
               callback.arguments = if expression.is_assigned() then [value.err, expression.recipient] else [value.err]
               callback.statements = _.rest expression.parent, expression.position + 1
               
               # remove sibling statements.
               while expression.parent.length > (expression.position + 1) then expression.parent.pop()
               
               # if lazy callback automatically manage errors. 
               if callback.is_lazy() then callback.statements.unshift(
                  ast.create.ifStatement(
                     value.err,
                     ast.create.ifStatement(
                        callback.lazy, # test callback existence.
                        ast.create.returnStatement(ast.create.callExpression(callback.lazy, [value.err, value.null])), # then block.
                        ast.create.throwStatement(value.err) # else block.
                     )
                  )
               )
               
               # if strict callback simply assign error (user will handle it manually).
               if expression.is_assigned() and callback.is_strict() then callback.statements.unshift(
                  ast.create.expressionStatement(
                     ast.create.assignmentExpression( '=',
                        expression.recipient,
                        ast.create.objectExpression([
                           ast.create.property 'init', ast.create.identifier('error'), value.err
                           ast.create.property 'init', ast.create.identifier('value'), expression.recipient
                        ]) 
                     )
                  )
               ) 
               
               # replace callback marker with callback function and nest siblings.
               callback.marker.replace ast.create.functionExpression(
                  null, # function name.
                  callback.arguments, # arguments
                  ast.create.blockStatement callback.statements # nested statements.
               )
               
               # wrap call in a return statement.
               expression.node.replace ast.create.returnStatement(expression.call)
            
            @.traverse path
      
      back null, { code: ast.format(sintax), source_map: source_map }
   catch err then return back err
