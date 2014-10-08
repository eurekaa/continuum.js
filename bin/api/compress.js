// Generated by CoffeeScript 1.7.1
(function() {
  var csswring, fs, imagemin, path, source_map, uglify, _;

  fs = require('fs');

  path = require('path');

  _ = require('lodash');

  _.mixin(require('underscore.string').exports());

  uglify = require('uglify-js');

  csswring = require('csswring').wring;

  imagemin = require('imagemin');

  source_map = require('./source_map.js');


  /*
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
   */

  exports['javascript'] = function(input, back) {
    var ast, compressor, err, options, output, stream;
    if (!_.isFunction(back)) {
      throw new Error('callback is required {function}.');
    }
    if (!_.isObject(input)) {
      return back(new Error('input is required {object}.'));
    }
    if (!_.isString(input.file)) {
      return back(new Error('input.file is required {string}.'));
    }
    if (_.isObject(input.source_map && !_.isArray(input.source_map.sources))) {
      return back(new Error('input.source_map.sources is required {array}.'));
    }
    try {
      input.code = input.code || fs.readFileSync(input.file, 'utf-8');
      output = {};
      output.code = null;
      output.source_map = null;
      output.warnings = [];
      ast = uglify.parse(input.code);
      ast.figure_out_scope();
      compressor = uglify.Compressor({
        warnings: false
      });
      ast = ast.transform(compressor);
      ast.figure_out_scope();
      ast.compute_char_frequency();
      ast.mangle_names();
      options = {};
      if (_.isObject(input.source_map)) {
        options.source_map = uglify.SourceMap({
          file: input.source_map.file || '',
          root: input.source_map.sourceRoot || '',
          orig: _.has(input.source_map, 'mappings') ? input.source_map : void 0
        });
      }
      stream = uglify.OutputStream(options);
      ast.print(stream);
      output.code = stream.toString();
      if (_.isObject(input.source_map)) {
        output.source_map = JSON.parse(options.source_map.toString());
        output.source_map.sources = input.source_map.sources || [];
      }
      return back(null, output);
    } catch (_error) {
      err = _error;
      return back(err);
    }
  };

  exports['stylesheet'] = function(input, back) {
    var err, options, output, result;
    if (!_.isFunction(back)) {
      throw new Error('callback is required {function}.');
    }
    if (!_.isObject(input)) {
      return back(new Error('input is required {object}.'));
    }
    if (!_.isString(input.file)) {
      return back(new Error('input.file is required {string}.'));
    }
    if (_.isObject(input.source_map && !_.isArray(input.source_map.sources))) {
      return back(new Error('input.source_map.sources is required {array}.'));
    }
    try {
      input.code = input.code || fs.readFileSync(input.file, 'utf-8');
      output = {};
      output.code = null;
      output.source_map = null;
      output.warnings = [];
      options = {};
      options.preserveHacks = true;
      options.removeAllComments = true;
      if (_.isObject(input.source_map)) {
        options.map = {};
        options.map.annotation = false;
        if (_.has(input.source_map, 'mappings')) {
          options.map.prev = input.source_map;
        }
      }
      result = csswring(input.code, options);
      output.code = result.css;
      if (_.isObject(input.source_map)) {
        output.source_map = JSON.parse(result.map.toString());
        output.source_map.file = input.source_map.file || '';
        output.source_map.sources = input.source_map.sources || [];
        output.source_map.sourceRoot = input.source_map.sourceRoot || '';
      }
      return back(null, output);
    } catch (_error) {
      err = _error;
      return back(err);
    }
  };

  exports['image'] = function(input, back) {
    var batch, err, output;
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
      input.extension = path.extname(input.file).toLowerCase().replace('.', '');
      if (_.isEmpty(input.code)) {
        input.code = fs.readFileSync(input.file, 'base64');
      }
      output = {};
      output.code = null;
      output.source_map = null;
      output.warnings = [];
      batch = new imagemin();
      batch.src(new Buffer(input.code, 'base64'));
      if (input.extension === 'png') {
        batch.use(imagemin.pngquant());
      }
      if (input.extension === 'gif') {
        batch.use(imagemin.gifsicle({
          interlaced: false
        }));
      }
      if (input.extension === 'jpg' || input.extension === 'jpeg') {
        batch.use(imagemin.jpegtran({
          progressive: true
        }));
      }
      if (input.extension === 'svg') {
        batch.use(imagemin.svgo());
      }
      return batch.run(function(err, compressed) {
        if (err) {
          return back(err);
        }
        output.code = new Buffer(compressed[0].contents).toString('base64');
        return back(null, output);
      });
    } catch (_error) {
      err = _error;
      return back(err);
    }
  };

  exports['js'] = this['javascript'];

  exports['css'] = this['stylesheet'];

  exports['png'] = this['image'];

  exports['gif'] = this['image'];

  exports['jpg'] = this['image'];

  exports['jpeg'] = this['image'];

  exports['svg'] = this['image'];

}).call(this);

//# sourceMappingURL=compress.map