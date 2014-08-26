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
json = require 'json-comments'


# linters.
jshint = require('jshint').JSHINT
csslint = require('csslint').CSSLint
htmlint = require 'html5-lint'

strip_comments = require 'strip-comments'
uglify = require 'uglifyjs'

# generators.
ast =
   parse: require('esprima').parse
   format: require('escodegen').generate
   walk: require('ast-types').visit
   types: require('ast-types').namedTypes
   create: require('ast-types').builders


###
   @options {object}
   @options.input {object}
   @options.input.file {string}
   @options.input.code [string] 
   @options.source_map [object]
   @options.source_map.root [string]: source map root path.
   @options.source_map.input [string]: source map input path.
   @options.source_map.output {string}: source map output path.
   @options.config [object]: additional compiler configurations. 
   @back {function}
###

coffeescript = require 'coffee-script'
livescript = require 'LiveScript'
sass = require 'node-sass'
stylus = require 'stylus'
less = require 'less'
jade = require 'jade'

exports['compile'] = (options, back)->
   try
      if not options or _.isFunction options then return back new Error('options are required.')
      if not back or not _.isFunction back then return back new Error('callback is required.')

      input = {}
      if not options.input then return back new Error('options.input is required.')
      if not options.input.file then return back new Error('options.input.file is required.')
      input.file = options.input.file
      input.extension = path.extname(input.file).replace '.', ''
      input.code = options.input.code or fs.readFileSync input.file, 'utf-8'
      
      source_map = {}
      source_map.is_enabled = -> options.source_map isnt undefined
      if source_map.is_enabled() and not _.isString options.source_map.output then return back new Error 'options.source_map.output is required.'
      source_map.root = options.source_map?.root
      source_map.input = options.source_map?.input or input.file
      source_map.output = options.source_map?.output
      
      output = {}
      output.code = undefined
      output.source_map = undefined
      
      
      # *** COFFEESCRIPT ***
      if input.extension is 'coffee'
         config =
            filename: input.file
            sourceMap: source_map.is_enabled()
            sourceRoot: source_map.root
            sourceFiles: source_map.input
            generatedFile: source_map.output
         config = _.merge config, (options.config or {})
         compiled = coffeescript.compile input.code, config
         output.code = compiled.js or compiled
         output.source_map = compiled.v3SourceMap or undefined
         return back null, output
      
      
      # *** LIVESCRIPT *** http://livescript.net/#usage
      #todo: add source map support (use --ast).
      else if input.extension is 'ls'
         output.code = livescript.compile input.code #, options.config
         return back null, output
      
      
      # *** SASS ***
      else if input.extension is 'sass' or input.extension is 'scss'
         config = {}
         config.file = input.file
         config.sourceComments = if source_map.is_enabled() then 'map' else 'none'
         config.sourceMap = '.' # bugfix: use fake path and replace later.
         config.outFile = '.'
         config = _.merge config, (options.config or {})
         sass.render _.merge config,
            
            success: (compiled, map)->
               # (problems with wrong paths in source_map. can't parse cause '\' instead of '\\'. 
               # extract mapping and recreate object).
               mappings = _.strRight(map, '"mappings":')
               mappings = _.trim(mappings).replace(/\}/g, '').replace(/\n/g, '').replace(/"/g, '')
               output.source_map =
                  version: 3
                  file: source_map.output
                  sourceRoot: source_map.root or ''
                  sources: [source_map.input]
                  names: []
                  mappings: mappings
               output.source_map = JSON.stringify output.source_map, null, 4
               output.code = strip_comments compiled
               return back null, output
            
            error: (err)->
               return back new Error(err.replace(options.input_file + ':', '').replace('\n', ''))
      
      
      # *** LESS ***
      else if input.extension is 'less'
         less.render input.code, (err, compiled)->
            if err then return back err
            output.code = compiled
            return back null, output
      
      
      # *** STYLUS ***
      else if input.extension is 'styl' or input.extension is 'stylus'
         stylus.render input.code,
            filename: input.file
            sourcemaps: source_map.is_enabled()
            compress: false
            linenos: true
         , (err, compiled)->
            if err then return back err
            output.code = compiled
            return back null, output
      
      
      # *** JADE ***
      else if input.extension is 'jade'
         jade.render input.code, options.config, (err, compiled)->
            if err then return back err
            output.code = compiled
            return back null, output
      
      
      else # unknown compiler.
         output.code = input.code
         return back null, output
   
   catch err then return back err



exports['analize'] = (input_file, input_code, options, back)->
   try
      if _.isFunction options then back = options; options = {}
      input_extension = path.extname(input_file).replace('.', '')
      options = options or {} 
      warnings = []
      switch input_extension
         
         when 'js'
            result = jshint input_code, options 
            if result is false
               for warn in jshint.errors when warn isnt null 
                  warnings.push
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
      
      
      # reference: https://github.com/benjamn/ast-types/blob/master/def/core.js
      # transform function declarations containing callback marker.
      ast.walk sintax.body, visitFunction: (path)->
         declaration = {}
         declaration.statements = path.node.body
         declaration.parameters = path.node.params
         callback.is_lazy = -> _.contains _.pluck(declaration.parameters, 'name'), callback.lazy.name
         callback.is_strict = -> _.contains _.pluck(declaration.parameters, 'name'), callback.strict.name
         callback.name = if callback.is_lazy() then callback.lazy.name else callback.strict.name
         callback.position = _.findIndex declaration.parameters, (parameter)-> parameter.name is callback.name
         
         if callback.is_strict() or callback.is_lazy()
            
            # rewrite return statement. 
            ast.walk path.node, visitReturnStatement: (path)->
               path.get('argument').replace if callback.is_strict()
                  ast.create.callExpression(callback.lazy, [value.null, path.node.argument])
               else ast.create.conditionalExpression(callback.lazy,
                  ast.create.callExpression(callback.lazy, [value.null, path.node.argument]),
                  path.node.argument
               )
               @.traverse path
            
            # when strict replace callback parameter with lazy name and add existence test.
            if callback.is_strict()
               path.get('params', callback.position).replace callback.lazy
               declaration.statements.body.unshift ast.create.ifStatement(
                  ast.create.binaryExpression('!==', ast.create.unaryExpression('typeof', callback.lazy), ast.create.literal 'function'),
                  ast.create.returnStatement(ast.create.callExpression(callback.strict, 
                     [ast.create.newExpression(ast.create.identifier('Error'), [ast.create.literal('Missing callback.')])]
                  ))
               )
            
            # inject try catch block.
            path.get('body').replace ast.create.blockStatement [ ast.create.tryStatement(
               declaration.statements, 
               ast.create.catchClause( value.err, null, ast.create.blockStatement [
                  ast.create.returnStatement(ast.create.conditionalExpression(callback.lazy,
                     ast.create.callExpression(callback.lazy, [value.err]),
                     ast.create.callExpression(callback.strict, [value.err])
                  ))
               ])
            )]
         
         @.traverse path
      
      
      # transform function calls containing callback marker.
      ast.walk sintax.body, visitExpression: (path)->
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
            
            # if lazy callback automatically bubble error. 
            if callback.is_lazy() then callback.statements.unshift(
               ast.create.ifStatement(
                  value.err,
                  ast.create.returnStatement(ast.create.conditionalExpression(callback.lazy,
                     ast.create.callExpression(callback.lazy, [value.err]),
                     ast.create.callExpression(callback.strict, [value.err])
                  ))
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
      
      
      # inject callback helper function.
      ast.walk sintax, visitBlockStatement: (path)->
         path.get('body').unshift ast.create.variableDeclaration( 'var', [ast.create.variableDeclarator( callback.strict,
            ast.create.functionExpression(null, [value.err], ast.create.blockStatement([
               # declare global 'target': window if browser, global if nodejs.
               ast.create.variableDeclaration('var', [ast.create.variableDeclarator(ast.create.identifier('target'),
                  ast.create.conditionalExpression(ast.create.binaryExpression('!==', ast.create.unaryExpression('typeof', ast.create.identifier('window')), ast.create.literal 'undefined'),
                  ast.create.identifier('window'), ast.create.identifier('global')
                  )
               )]),
               # bubble error to 'on_error' function on target if defined, throw it otherwise.
               ast.create.ifStatement(
                  ast.create.identifier('target.on_error'),
                  ast.create.returnStatement(ast.create.callExpression(ast.create.identifier('target.on_error'),
                     [value.err]))
                  ast.create.throwStatement(value.err)
               )
            ]))
         )])
         
         
         # do not continue traversing.
         return false
      
      # generate code.
      code = ast.format sintax
      
      return back null, code: code, source_map: source_map
   catch err then return back err


exports['compress'] = (input_file, input_code, options, back)->
   code = uglify.minify(code,
      fromString: true
      mangle: false
      beautify: true
   ).code
