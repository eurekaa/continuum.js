// Generated by CoffeeScript 1.7.1
(function() {
  var ast, fs, source_map, _;

  fs = require('fs');

  _ = require('lodash');

  _.mixin(require('underscore.string').exports());

  ast = {};

  ast.parse = require('acorn').parse;

  ast.format = require('escodegen').generate;

  ast.walk = require('ast-types').visit;

  ast.create = require('ast-types').builders;

  ast.types = require('ast-types').namedTypes;

  source_map = require('./source_map.js');


  /*
     @name: cps
     @description: performs continuous passing style transformation on javascript files.
     @param: input {object}: 
        file {string}: path to javascript file. 
        code [string]: raw javascript code. wins on options.file.
        ast [object]: valid ast object rappresenting javascript code (with locations if you want source mapping). wins on options.code and options.file.
        source_map [object|string]: if defined will try to generate a Mozilla V3 source map or to update an existing one.
           file {string}: output file path (absolute or relative to source map file).   
           sources {array}: an array of source paths involved in mapping.
           sourceRoot [string]: root path prepended to source paths.
           mappings [string]: if not empty will renew the source map, creates a new one otherwise.
        options [object]: additional transformer configurations.
           lazy_marker [string]: the marker to be replaced with lazy callback (without returning errors).
           strict_marker [string]: the marker to be replaced with strict callback (returning errors).
     @param back {function}: asynchronous callback function.
     @return output {object}:
        code {string}: transformed string code.
        source_map {object}: source map if required, null otherwise.
        warnings {array}: transformation warnings.
   */

  exports['cps'] = function(input, back) {
    var callback, err, output, transformed, _ref, _ref1;
    if (!_.isFunction(back)) {
      throw new Error('callback is required {function}.');
    }
    if (!_.isObject(input)) {
      return back(new Error('input is required {object}.'));
    }
    if (!_.isString(input.file)) {
      return back(new Error('input.file is required {string}.'));
    }
    try {
      if (_.isString(input.source_map)) {
        input.source_map = JSON.parse(input.source_map);
      }
      input.source_map_enabled = _.isObject(input.source_map);
      input.source_map_exists = input.source_map_enabled === true && _.has(input.source_map, 'mappings') && !_.isEmpty(input.source_map.mappings);
      if (input.source_map_enabled === true && !_.isString(input.source_map.file)) {
        return back(new Error('input.source_map.file is required {string}.'));
      }
      if (input.source_map_enabled === true && !_.isArray(input.source_map.sources)) {
        return back(new Error('input.source_map.sources is required {array}.'));
      }
      if (!_.isString(input.code || !_.isObject(input.ast))) {
        input.code = fs.readFileSync(input.file, 'utf-8');
      }
      if (!_.isObject(input.ast)) {
        input.ast = ast.parse(input.code, {
          locations: input.source_map_enabled
        });
      }
      output = {};
      output.code = null;
      output.source_map = null;
      output.warnings = [];
      callback = {};
      callback.lazy = ast.create.identifier(((_ref = input.options) != null ? _ref.lazy_marker : void 0) || '$back');
      callback.strict = ast.create.identifier(((_ref1 = input.options) != null ? _ref1.strict_marker : void 0) || '$throw');
      callback["null"] = ast.create.identifier('null');
      callback.error = ast.create.identifier('error');
      ast.walk(input.ast, {
        visitFunction: function(path) {
          var declaration;
          declaration = {};
          declaration.statements = path.node.body;
          declaration.parameters = path.node.params;
          callback.is_lazy = function() {
            return _.contains(_.pluck(declaration.parameters, 'name'), callback.lazy.name);
          };
          callback.is_strict = function() {
            return _.contains(_.pluck(declaration.parameters, 'name'), callback.strict.name);
          };
          callback.name = callback.is_lazy() ? callback.lazy.name : callback.strict.name;
          callback.position = _.findIndex(declaration.parameters, function(parameter) {
            return parameter.name === callback.name;
          });
          if (callback.is_strict() || callback.is_lazy()) {
            ast.walk(path.node, {
              visitReturnStatement: function(path) {
                path.get('argument').replace(callback.is_strict() ? ast.create.callExpression(callback.lazy, [callback["null"], path.node.argument]) : ast.create.conditionalExpression(callback.lazy, ast.create.callExpression(callback.lazy, [callback["null"], path.node.argument]), path.node.argument));
                return this.traverse(path);
              }
            });
            if (callback.is_strict()) {
              path.get('params', callback.position).replace(callback.lazy);
              declaration.statements.body.unshift(ast.create.ifStatement(ast.create.binaryExpression('!==', ast.create.unaryExpression('typeof', callback.lazy), ast.create.literal('function')), ast.create.returnStatement(ast.create.callExpression(callback.strict, [ast.create.newExpression(ast.create.identifier('Error'), [ast.create.literal('Missing callback.')])]))));
            }
            path.get('body').replace(ast.create.blockStatement([ast.create.tryStatement(declaration.statements, ast.create.catchClause(callback.error, null, ast.create.blockStatement([ast.create.returnStatement(ast.create.conditionalExpression(callback.lazy, ast.create.callExpression(callback.lazy, [callback.error]), ast.create.callExpression(callback.strict, [callback.error])))])))]));
          }
          return this.traverse(path);
        }
      });
      ast.walk(input.ast, {
        visitExpression: function(path) {
          var expression;
          expression = {};
          expression.is_assigned = function() {
            return ast.types.AssignmentExpression.check(path.node);
          };
          expression.call = expression.is_assigned() ? path.node.right : path.node;
          expression["arguments"] = expression.call["arguments"];
          expression.is_call = function() {
            return ast.types.CallExpression.check(expression.call);
          };
          callback.is_lazy = function() {
            return _.contains(_.pluck(expression["arguments"], 'name'), callback.lazy.name);
          };
          callback.is_strict = function() {
            return _.contains(_.pluck(expression["arguments"], 'name'), callback.strict.name);
          };
          if (expression.is_call() && (callback.is_lazy() || callback.is_strict())) {
            expression.node = path.parent;
            expression.recipient = expression.is_assigned() ? path.node.left : null;
            expression.path = expression.is_assigned() ? path.get('right') : path;
            expression.position = expression.node.name;
            expression.parent = expression.node.parentPath.value;
            callback.name = callback.is_lazy() ? callback.lazy.name : callback.strict.name;
            callback.position = _.findIndex(expression["arguments"], function(arg) {
              return arg.name === callback.name;
            });
            callback.marker = expression.path.get('arguments', callback.position);
            callback["arguments"] = expression.is_assigned() ? [callback.error, expression.recipient] : [callback.error];
            callback.statements = _.rest(expression.parent, expression.position + 1);
            while (expression.parent.length > (expression.position + 1)) {
              expression.parent.pop();
            }
            if (callback.is_lazy()) {
              callback.statements.unshift(ast.create.ifStatement(callback.error, ast.create.returnStatement(ast.create.conditionalExpression(callback.lazy, ast.create.callExpression(callback.lazy, [callback.error]), ast.create.callExpression(callback.strict, [callback.error])))));
            }
            if (expression.is_assigned() && callback.is_strict()) {
              callback.statements.unshift(ast.create.expressionStatement(ast.create.assignmentExpression('=', expression.recipient, ast.create.objectExpression([ast.create.property('init', ast.create.identifier('error'), callback.error), ast.create.property('init', ast.create.identifier('value'), expression.recipient)]))));
            }
            callback.marker.replace(ast.create.functionExpression(null, callback["arguments"], ast.create.blockStatement(callback.statements)));
            expression.node.replace(ast.create.returnStatement(expression.call));
          }
          return this.traverse(path);
        }
      });
      ast.walk(input.ast, {
        visitProgram: function(path) {
          path.get('body').unshift(ast.create.variableDeclaration('var', [ast.create.variableDeclarator(callback.strict, ast.create.functionExpression(null, [callback.error], ast.create.blockStatement([ast.create.variableDeclaration('var', [ast.create.variableDeclarator(ast.create.identifier('target'), ast.create.conditionalExpression(ast.create.binaryExpression('!==', ast.create.unaryExpression('typeof', ast.create.identifier('window')), ast.create.literal('undefined')), ast.create.identifier('window'), ast.create.identifier('global')))]), ast.create.ifStatement(ast.create.identifier('target.on_error'), ast.create.returnStatement(ast.create.callExpression(ast.create.identifier('target.on_error'), [callback.error])), ast.create.throwStatement(callback.error))])))]));
          return false;
        }
      });
      transformed = ast.format(input.ast, {
        sourceMapWithCode: input.source_map_enabled,
        sourceMap: input.source_map_enabled === true ? input.source_map.sources[0] : void 0
      });
      output.code = transformed.code || transformed;
      if (input.source_map_enabled === true) {
        output.source_map = JSON.parse(transformed.map);
        output.source_map.file = input.source_map.file;
        output.source_map.sourceRoot = input.source_map.sourceRoot || '';
        if (input.source_map_exists === true) {
          output.source_map = source_map.map_back(output.source_map, input.source_map);
        }
      }
      return back(null, output);
    } catch (_error) {
      err = _error;
      return back(err);
    }
  };

}).call(this);

//# sourceMappingURL=transform.map
