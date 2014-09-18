# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa
# File Name: api
# Created: 22/07/14 18.46


# require utilities.
fs = require 'fs'
path = require 'path' 
string = require 'string'
_ = require 'lodash'
_.mixin require('underscore.string').exports()
string = require 'string'
async = require 'async'
strip_comments = require 'strip-comments'

# require compilers (transpillers).
coffeescript = require 'coffee-script'
livescript = require 'LiveScript'
sass = require 'node-sass'
stylus = require 'stylus'
less = require 'less'
jade = require 'jade'

# require linters.
jshint = require('jshint').JSHINT
csslint = require('csslint').CSSLint
htmlint = require 'html5-lint'

# require compressors.
uglify = require 'uglifyjs'

# require javascript transformators.
ast = {} 
ast.parse = require('acorn').parse
ast.format = require('escodegen').generate
ast.create = require('ast-types').builders
ast.types = require('ast-types').namedTypes
ast.walk = require('ast-types').visit

# require source map handlers.
source_map = {} 
source_map.parse = require('source-map').SourceMapConsumer
source_map.generate = require('source-map').SourceMapGenerator
source_map.update = (original, generated)->
   generated = new source_map.parse generated
   original = new source_map.parse original
   remapped = new source_map.generate()
   original.eachMapping (map)->
      # { source, generatedLine, generatedColumn, originalLine, originalColumn, name }
      last = generated.generatedPositionFor source: map.source, line: map.generatedLine, column: map.generatedColumn
      remapped.addMapping
         original: line: map.originalLine, column: map.originalColumn
         generated: line: last.line, column: last.column
         source: map.source
         name: map.name
   remapped = JSON.parse remapped.toString()
   remapped.file = original.file
   return remapped

source_map.get_original_position = (map, position)->
   map = new source_map.parse map
   return map.originalPositionFor position



###
   @name: compile
   @description: compiles sources using the appropriate compiler.
   @todo: add source map support for every compiler.
   
   @params:
   @input {object}
   @input.file {string}: input file path (will be used to select the appropriate compiler).
   @input.code [string]: raw code (compiles the code without reading it from file sytem).
   @options.source_map [object]: if defined compilation will try to generate a Mozilla V3 source map (not available for all compilers).
   @options.source_map.file [string]: output file path (absolute or relative to source map file).
   @options.source_map.sourceRoot [string]: root path prepended to source paths.
   @options.source_map.sources {array}: an array of source paths involved in mapping. 
   @options.config [object]: additional compiler configurations. 
   @back {function}
   
   @return output {object}:
   @output.code {string}: compiled string code.
   @output.source_map {object}: source map if required, null otherwise.
   @output.warnings {array}: compilation warnings.
###

exports['compile'] = (input, options, back)->
   try
      if not _.isFunction back then return throw new Error('callback is required {function}.')
      if not _.isObject input then return back new Error('input is required {object}.')
      if not _.isObject options then return back new Error('options is required {object}.')
      if not input.file then return back new Error('input.file is required {string}.')
      if _.isObject options.source_map and not _.isArray options.source_map.sources then return back new Error 'options.source_map.sources is required {array}.'
      
      input.extension = path.extname(input.file).replace '.', ''
      input.code = input.code or fs.readFileSync input.file, 'utf-8'    
      
      output = {}
      output.code = null
      output.source_map = null
      output.warnings = []
      
      
      # *** COFFEESCRIPT ***
      if input.extension is 'coffee'
         config = {}
         config.filename = input.file
         if _.isObject options.source_map
            config.sourceMap = true
            config.sourceRoot = options.source_map.root or ''
            config.sourceFiles = options.source_map.sources
            config.generatedFile = options.source_map.file or ''
         config = _.merge config, (options.config or {})
         compiled = coffeescript.compile input.code, config
         output.code = compiled.js or compiled
         output.source_map = if compiled.v3SourceMap then JSON.parse(compiled.v3SourceMap) else null
         return back null, output
      
      
      # *** LIVESCRIPT *** http://livescript.net/#usage
      #todo: add source map support (use --ast).
      else if input.extension is 'ls'
         if _.isObject options.source_map then output.warnings.push 'livescript doesn\'t support source maps.'
         output.code = livescript.compile input.code #, options.config
         return back null, output
      
      
      # *** SASS ***
      else if input.extension is 'sass' or input.extension is 'scss'
         config = {}
         config.file = input.file
         config.data = input.code
         if _.isObject options.source_map
            config.sourceComments = 'map'
            config.sourceMap = '.' # bugfix: use fake path and replace later.
            config.outFile = '.'
         config = _.merge config, (options.config or {})
         sass.render _.merge config,
            
            success: (compiled, map)->
               # (problems with wrong paths in source_map. can't parse cause '\' instead of '\\'. 
               # extract mapping and recreate object).
               try
                  if _.isObject options.source_map
                     mappings = _.strRight(map, '"mappings":')
                     mappings = _.trim(mappings).replace(/\}/g, '').replace(/\n/g, '').replace(/"/g, '')
                     output.source_map =
                        version: 3
                        file: options.source_map.file
                        sourceRoot: options.source_map.root or ''
                        sources: options.source_map.sources
                        names: []
                        mappings: mappings
                  output.code = strip_comments compiled
                  return back null, output
               catch err then return back err
            
            error: (err)->
               return back new Error(err.replace(options.file + ':', '').replace('\n', ''))
      
      
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
            sourcemaps: _.isObject options.source_map
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


exports['analize'] = (input, options, back)->
   if not _.isFunction back then return throw new Error('callback is required {function}.')
   if not _.isObject input then return back new Error('input is required {object}.')
   if not _.isObject options then return back new Error('options is required {object}.')
   if not _.isString input.file then return back new Error('input.file is required {string}.')

   try
      input.extension = path.extname(input.file).replace('.', '')
      input.code = fs.readFileSync input.file, 'utf-8' if not input.code
      
      output = {}
      output.warnings = []
      
      if input.extension is 'js'
         result = jshint input.code, options.config 
         if result is false
            for warn in jshint.errors when warn isnt null
               # translate position if a source_map is provided.
               position = line: warn.line, column: warn.character
               if _.isObject options.source_map 
                  position = source_map.get_original_position options.source_map, 
                     source: options.source_map.sources[0], 
                     line: warn.line, 
                     column: warn.character
               output.warnings.push
                  message: _.trim warn.reason
                  evidence: _.trim warn.evidence
                  line: position.line 
                  column: position.column
         return back null, output
         
      else if input.extension is 'css'
         result = csslint.verify input.code, options.config
         for warn in result.messages then output.warnings.push 
            message: _.trim _.strLeft(warn.message, 'at line')
            evidence: _.trim warn.evidence 
            line: warn.line
            column: warn.col
         return back null, output
         
      else if input.extension is 'html' or input.extension is 'htm' 
         htmlint input.code, options.config, (err, result)->
            if err then return back err
            for warn in result.messages then output.warnings.push
               message: _.trim warn.message
               evidence: _.trim warn.extract + '..'
               line: warn.lastLine
               column: warn.lastColumn
            return back null, output
         
      else return back null, output
   
   catch err then return back err, []


###
   @name: transform
   @description: performs continuous passing style transformation on javascript files.
   @params:
   @options {object}

      @options.file {string}: path to javascript file. 
      @options.code [string]: raw javascript code. wins on options.file.
      @options.ast [object]: valid ast object rappresenting javascript code (with locations if you want source mapping). wins on options.code and options.file.
      @options.source_map [object|string]: if defined will try to generate a Mozilla V3 source map or to update an existing one.
      @options.source_map.file {string}: output file path (absolute or relative to source map file).   
      @options.source_map.sources {array}: an array of source paths involved in mapping.
      @options.source_map.sourceRoot [string]: root path prepended to source paths.
      @options.source_map.mappings [string]: if not empty will renew the source map, creates a new one otherwise.
      
      @options.config [object]: additional transformer configurations.
      @options.config.lazy_marker [string]: the marker to be replaced with lazy callback (without returning errors).
      @options.config.strict_marker [string]: the marker to be replaced with strict callback (returning errors).
   
   @back {function}
   
   @returns {object}
      file {string}: input file path.
      code {string}: transformed code
      ast {object}: transformed ast.
      source_map {object}: source maps (new or renewed).
      warnings {array}: transformation warnings.
###

exports['transform_cps'] = (input, options, back)->

   try
      if _.isUndefined back or not _.isFunction back then return throw new Error('callback is required {function}.')
      if not _.isObject options then return back new Error('options is required {object}.')
      if not _.isObject input then return back new Error('input is required {object}.')
      if not _.isString input.file then return back new Error('input.file is required {string}.')
      
      options.source_map = JSON.parse options.source_map if _.isString options.source_map
      options.source_map_enabled = _.isObject options.source_map 
      options.source_map_exists = (options.source_map_enabled is true and _.has(options.source_map, 'mappings') and not _.isEmpty(options.source_map.mappings))
      if options.source_map_enabled is true and not _.isString options.source_map.file then return back new Error 'options.source_map.file is required [string].'
      if options.source_map_enabled is true and not _.isArray options.source_map.sources then return back new Error 'options.source_map.sources is required [array].'
      
      # parse code.
      input.code = fs.readFileSync input.file, 'utf-8' if not _.isString input.code or not _.isObject input.ast
      input.ast = ast.parse input.code, locations: _.isObject options.source_map if not _.isObject input.ast
      
      
      # start with continuous passing style transformation.
      # types reference: https://github.com/benjamn/ast-types/blob/master/def/core.js
      callback = {}
      callback.lazy = ast.create.identifier(options.config.lazy_marker or '$back')
      callback.strict = ast.create.identifier(options.config.strict_marker or '$throw')
      callback.null = ast.create.identifier 'null'
      callback.error = ast.create.identifier 'error'
      
      # todo: add closure if not present.
      
      # transform function declarations containing callback marker.
      ast.walk input.ast, visitFunction: (path)->
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
                  ast.create.callExpression(callback.lazy, [callback.null, path.node.argument])
               else ast.create.conditionalExpression(callback.lazy,
                  ast.create.callExpression(callback.lazy, [callback.null, path.node.argument]),
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
               ast.create.catchClause( callback.error, null, ast.create.blockStatement [
                  ast.create.returnStatement(
                     ast.create.conditionalExpression(callback.lazy,
                        ast.create.callExpression(callback.lazy, [callback.error]),
                        ast.create.callExpression(callback.strict, [callback.error])
                     )
                  )
               ])
            )]
         
         @.traverse path
      
      # transform function calls containing callback marker.
      ast.walk input.ast, visitExpression: (path)->
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
            callback.arguments = if expression.is_assigned() then [callback.error, expression.recipient] else [callback.error]
            callback.statements = _.rest expression.parent, expression.position + 1
            
            # remove sibling statements.
            while expression.parent.length > (expression.position + 1) then expression.parent.pop()
            
            # if lazy callback automatically bubble error. 
            if callback.is_lazy() then callback.statements.unshift(
               ast.create.ifStatement(
                  callback.error,
                  ast.create.returnStatement(ast.create.conditionalExpression(callback.lazy,
                     ast.create.callExpression(callback.lazy, [callback.error]),
                     ast.create.callExpression(callback.strict, [callback.error])
                  ))
               )
            )
            
            # if strict callback simply assign error (user will handle it manually).
            if expression.is_assigned() and callback.is_strict() then callback.statements.unshift(
               ast.create.expressionStatement(
                  ast.create.assignmentExpression( '=',
                     expression.recipient,
                     ast.create.objectExpression([
                        ast.create.property 'init', ast.create.identifier('error'), callback.error
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
      ast.walk input.ast, visitBlockStatement: (path)->
         path.get('body').unshift ast.create.variableDeclaration( 'var', [ast.create.variableDeclarator( callback.strict,
            ast.create.functionExpression(null, [callback.error], ast.create.blockStatement([
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
                     [callback.error]))
                  ast.create.throwStatement(callback.error)
               )
            ]))
         )])
         
         
         # do not continue traversing.
         return false
      
      # generate code.
      transformed = ast.format input.ast,
         sourceMapWithCode: options.source_map_enabled
         sourceMap: options.source_map.sources[0] if options.source_map_enabled is true

      output = {}
      output.code = transformed.code or transformed
      
      # add escodegen missing properties.
      if options.source_map_enabled is true
         output.source_map = JSON.parse transformed.map
         output.source_map.file = options.source_map.file
         output.source_map.sourceRoot = options.source_map.sourceRoot or ''
         # renew source map if an existing is provided.
         if options.source_map_exists is true 
            output.source_map = source_map.update options.source_map, output.source_map
         
      
      return back null, output
   catch err then return back err



exports['compress'] = (input_file, input_code, options, back)->
   code = uglify.minify(code,
      fromString: true
      mangle: false
      beautify: true
   ).code
