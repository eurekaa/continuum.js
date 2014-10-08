// Generated by CoffeeScript 1.7.1
(function() {
  var api, async, config, fs, fs_tools, log4js, path, string, strip_comments, _;

  fs = require('fs');

  fs_tools = require('fs-tools');

  path = require('path');

  string = require('string');

  async = require('async');

  _ = require('lodash');

  _.mixin(require('underscore.string').exports());

  strip_comments = require('strip-comments');

  log4js = require('log4js');

  api = require('./api.js');

  log4js.getBufferedLogger = function(category) {
    var base_logger, logger;
    base_logger = log4js.getLogger(category);
    logger = {};
    logger.temp = [];
    logger.base_logger = base_logger;
    logger.flush = function() {
      var i, log, _i, _len, _ref, _results;
      i = 0;
      _ref = logger.temp;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        log = _ref[_i];
        logger.base_logger[log.level](log.message);
        delete logger.temp[i];
        _results.push(i++);
      }
      return _results;
    };
    logger.trace = function(message) {
      return logger.temp.push({
        level: 'trace',
        message: message
      });
    };
    logger.debug = function(message) {
      return logger.temp.push({
        level: 'debug',
        message: message
      });
    };
    logger.info = function(message) {
      return logger.temp.push({
        level: 'info',
        message: message
      });
    };
    logger.warn = function(message) {
      return logger.temp.push({
        level: 'warn',
        message: message
      });
    };
    logger.error = function(message) {
      return logger.temp.push({
        level: 'error',
        message: message
      });
    };
    logger.fatal = function(message) {
      return logger.temp.push({
        level: 'fatal',
        message: message
      });
    };
    return logger;
  };

  exports['info'] = function() {
    var info;
    info = require('./../package.json');
    return {
      name: info.name,
      version: info.version,
      author: info.author,
      description: info.description,
      license: info.license,
      repository: info.repository.url,
      bugs: info.bugs.url
    };
  };

  config = null;

  exports['setup'] = function(options) {
    var appenders, commander, err, user_config, user_dir;
    try {
      config = fs.readFileSync(__dirname + '\\continuum.json', 'utf-8');
      config = strip_comments(config);
      config = JSON.parse(config);
    } catch (_error) {
      err = _error;
      throw new Error(__dirname + '\\continuum.json: ' + err);
    }
    try {
      user_dir = path.resolve(process.cwd());
      console.log(user_dir);
      if (fs.existsSync(user_dir + '\\continuum.json')) {
        user_config = fs.readFileSync(user_dir + '\\continuum.json', 'utf-8');
        user_config = strip_comments(user_config);
        user_config = JSON.parse(user_config);
        config = _.merge(config, user_config);
      }
    } catch (_error) {
      err = _error;
      throw new Error(user_dir + '\\continuum.json: ' + err);
    }
    config = _.merge(config, options || {});
    commander = require('commander');
    commander.version(this.info().version);
    commander.usage('[options]');
    commander.option('-i, --input <dir>', 'defines input directory for batching files.');
    commander.option('-o, --output <dir>', 'defines output directory for batched files.');
    commander.option('-t, --transformation', 'enables continuos passing style callbacks transformation.');
    commander.option('-s, --source_map [dir]', 'enables source maps generation and optionally defines directory.');
    commander.option('-c, --cache [dir]', 'enables files caching and optionally defines directory.');
    commander.option('-l, --log [dir]', 'enables logging and optionally defines directory.');
    commander.parse(process.argv);
    if (commander.input) {
      config.input.path = _.isString(commander.input) ? commander.input : config.input.path;
    }
    if (commander.output) {
      config.output.path = _.isString(commander.output) ? commander.output : config.output.path;
    }
    if (commander.cache) {
      config.cache.enabled = true;
      config.cache.path = _.isString(commander.cache) ? commander.cache : config.cache.path;
    }
    if (commander.source_map) {
      config.source_map.enabled = true;
      config.source_map.path = _.isString(commander.source_map) ? commander.source_map : config.source_map.path;
    }
    if (commander.log) {
      config.log.enabled = true;
      config.log.path = _.isString(commander.log) ? commander.log : config.log.path;
    }
    if (commander.transformation === true) {
      config.transformation.enabled = true;
    }
    if (config.input.path === '.') {
      config.input.path = './';
    }
    config.input.path = path.normalize(config.input.path);
    config.input.info = fs.lstatSync(config.input.path);
    if (config.output.path === '.') {
      config.output.path = './';
    }
    config.output.path = config.output.path ? path.normalize(config.output.path) : config.input.path;
    if (!fs.existsSync(config.output.path)) {
      fs_tools.mkdirSync(config.output.path);
    }
    config.output.info = fs.lstatSync(config.output.path);
    if (config.output.info.isFile()) {
      throw new Error('output must be a directory.');
    }
    if (config.cache.enabled === true) {
      if (config.cache.path === '.') {
        config.cache.path = './';
      }
      config.cache.path = config.cache.path ? path.normalize(config.cache.path) : config.input.path;
      if (!fs.existsSync(config.cache.path)) {
        fs_tools.mkdirSync(config.cache.path);
      }
      config.cache.info = fs.lstatSync(config.cache.path);
      if (config.cache.info.isFile()) {
        throw new Error('cache must be a directory');
      }
    }
    if (config.source_map.enabled === true) {
      if (config.source_map.path === '.') {
        config.source_map.path = './';
      }
      config.source_map.path = config.source_map.path ? path.normalize(config.source_map.path) : config.input.path;
      if (!fs.existsSync(config.source_map.path)) {
        fs_tools.mkdirSync(config.source_map.path);
      }
      config.source_map.info = fs.lstatSync(config.source_map.path);
      if (config.source_map.info.isFile()) {
        throw new Error('source_map must be a directory.');
      }
    }
    if (config.log.enabled === true) {
      appenders = [];
      if (config.log.levels.file.toLocaleUpperCase() !== 'OFF') {
        if (config.log.path === '.') {
          config.log.path = './';
        }
        config.log.path = config.log.path ? path.normalize(config.log.path) : config.input.path;
        if (!fs.existsSync(config.log.path)) {
          fs_tools.mkdirSync(config.log.path);
        }
        appenders.push({
          type: 'logLevelFilter',
          level: config.log.levels.file,
          appender: {
            type: 'file',
            filename: config.log.path + '\\' + config.log.name + '.' + config.log.extension,
            layout: {
              type: 'pattern',
              pattern: '[%d{yyyy-MM-dd hh:mm}] [%p] - %m'
            }
          }
        });
      }
      appenders.push({
        type: 'logLevelFilter',
        level: config.log.levels.console,
        appender: {
          type: 'console',
          layout: {
            type: 'pattern',
            pattern: '%[[%p]%] %m'
          }
        }
      });
      log4js.configure({
        appenders: appenders
      });
    } else {
      log4js.setGlobalLogLevel('OFF');
    }
    return config;
  };

  exports['run'] = function(options, back) {
    var batch, err, logger;
    try {
      if (_.isFunction(options)) {
        back = options;
        options = {};
      }
      config = this.setup(options);
      logger = log4js.getLogger(' ');
      batch = {};
      batch.directory = path.resolve(process.cwd());
      batch.processed = 0;
      batch.skipped = 0;
      batch.failures = 0;
      batch.successes = 0;
      batch.started = Date.now();
      logger.info('*** processing project: starting... ***');
      logger.debug('[input: ' + config.input.path + ', output: ' + config.output.path + ']\n');
      return fs_tools.walk(config.input.path, function(input_file, input_info, next) {
        var cache, failed, input, log, output, source_map, _ref, _ref1;
        input = {};
        input.extension = path.extname(input_file).replace('.', '').toLowerCase();
        input.file = input_file;
        input.directory = path.dirname(input.file);
        input.find_compiler = function() {
          return _.find(config.compilation.compilers, function(compiler) {
            if (_.isArray(compiler.input_extension)) {
              return _.contains(compiler.input_extension, input.extension);
            } else {
              return compiler.input_extension === input.extension;
            }
          });
        };
        input.encoding = input.extension === 'png' || input.extension === 'gif' || input.extension === 'jpg' || input.extension === 'jpeg' ? 'base64' : 'utf8';
        input.code = '';
        output = {};
        output.extension = (_ref = (_ref1 = input.find_compiler()) != null ? _ref1.output_extension.toLowerCase() : void 0) != null ? _ref : input.extension;
        output.file = input.file.replace(config.input.path, config.output.path).replace('.' + input.extension, '.' + output.extension);
        output.directory = config.output.path + '\\' + path.dirname(path.relative(config.output.path, output.file));
        output.is_js = function() {
          var _ref2;
          return input.extension === 'js' || ((_ref2 = input.find_compiler()) != null ? _ref2.output_extension : void 0) === 'js';
        };
        output.encoding = input.encoding;
        output.code = '';
        source_map = {};
        source_map.is_enabled = function() {
          return config.source_map.enabled === true;
        };
        source_map.extension = config.source_map.extension;
        source_map.file = input.file.replace(config.input.path, config.source_map.path).replace('.' + input.extension, '.' + source_map.extension);
        source_map.directory = config.source_map.path + '\\' + path.dirname(path.relative(config.source_map.path, source_map.file));
        source_map.link = '/*# sourceMappingURL=' + path.relative(output.directory, source_map.directory) + '\\' + path.basename(source_map.file) + ' */';
        source_map.code = source_map.is_enabled() ? {
          file: path.resolve(output.file),
          sources: [path.relative(source_map.directory, input.file)]
        } : void 0;
        cache = {};
        cache.is_enabled = function() {
          return config.cache.enabled === true;
        };
        cache.extension = config.cache.extension;
        cache.file = input.file.replace(config.input.path, config.cache.path).replace('.' + input.extension, '.' + cache.extension);
        cache.directory = config.cache.path + '\\' + path.dirname(path.relative(config.cache.path, cache.file));
        cache.exists = function() {
          return fs.existsSync(cache.file) && (input_info.mtime <= fs.lstatSync(cache.file).mtime);
        };
        cache.code = '';
        if (config.input.path !== config.output.path && string(input.directory).contains(config.output.path)) {
          return next();
        }
        if (config.input.path !== config.cache.path && string(input.directory).contains(config.cache.path)) {
          return next();
        }
        if (config.input.path !== config.source_map.path && string(input.directory).contains(config.source_map.path)) {
          return next();
        }
        if (config.input.path !== config.log.path && string(input.directory).contains(config.log.path)) {
          return next();
        }
        if (input.file === config.log.name + config.log.extension) {
          return next();
        }
        batch.processed++;
        if (cache.is_enabled() && cache.exists()) {
          batch.skipped++;
          return next();
        }
        log = log4js.getBufferedLogger(' ');
        log.info('processing file: ' + input.file);
        failed = false;
        return async.series([
          function(back) {
            return fs.readFile(input.file, {
              encoding: input.encoding
            }, function(err, result) {
              if (err) {
                failed = true;
                log.error(err.message);
                log.trace(err.stack);
                log.error('reading input: FAILED!');
              } else {
                input.code = result;
              }
              output.code = input.code;
              return back();
            });
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (output.is_js()) {
              if (config.transformation.enabled === false && (string(output.code).contains(config.transformation.lazy_marker || string(output.code).contains(config.transformation.strict_marker)))) {
                failed = true;
                log.error('callback markers detected but transformation is disabled.');
              } else {
                output.code = string(output.code).replaceAll(config.transformation.strict_marker, config.transformation.strict_safe_marker).replaceAll(config.transformation.lazy_marker, config.transformation.lazy_safe_marker).toString();
              }
            }
            return back();
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (config.compilation.enabled !== true) {
              return back();
            }
            if (!_.has(api.compile, input.extension)) {
              return back();
            }
            return api.compile[input.extension]({
              file: input.file,
              code: output.code,
              source_map: source_map.is_enabled() ? source_map.code : void 0,
              config: input.find_compiler() || {}
            }, function(err, result) {
              var warning, _i, _len, _ref2;
              if (err) {
                failed = true;
                log.error(err.message);
                log.trace(err.stack);
                log.error('compilation: FAILED!');
              } else {
                output.code = result.code;
                source_map.code = result.source_map;
                _ref2 = result.warnings;
                for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                  warning = _ref2[_i];
                  log.warn(warning);
                }
                log.debug('compilation: done! [warnings: ' + result.warnings.length + ']');
              }
              return back();
            });
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (config.transformation.enabled === false) {
              return back();
            }
            if (!output.is_js()) {
              return back();
            }
            if (!(string(output.code).contains(config.transformation.lazy_safe_marker || string(output.code).contains(config.transformation.strict_safe_marker)))) {
              return back();
            }
            return api.transform.cps({
              file: output.file,
              code: output.code,
              source_map: source_map.is_enabled() ? source_map.code : void 0,
              options: {
                lazy_marker: config.transformation.lazy_safe_marker,
                strict_marker: config.transformation.strict_safe_marker
              }
            }, function(err, result) {
              var warning, _i, _len, _ref2;
              if (err) {
                failed = true;
                log.error(err.message);
                log.trace(err.stack);
                log.error('cps transformation: FAILED!');
              } else {
                output.code = result.code;
                source_map.code = result.source_map;
                _ref2 = result.warnings;
                for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                  warning = _ref2[_i];
                  log.warn(warning);
                }
                log.debug('cps transformation: done! [warnings: ' + result.warnings.length + ']');
              }
              return back();
            });
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (config.analysis.enabled !== true) {
              return back();
            }
            if (!_.has(api.analize, output.extension)) {
              return back();
            }
            return api.analize[output.extension]({
              file: output.file,
              code: output.code,
              source: input.code,
              source_map: source_map.is_enabled() ? source_map.code : void 0,
              options: config.analysis[output.extension] || {}
            }, function(err, warnings) {
              var legend, type, warning, _i, _len;
              if (err) {
                log.error(err.message);
                log.trace(err.stack);
                log.error('code analysis: FAILED!');
              } else {
                warnings = _.sortBy(warnings, function(warning) {
                  return warning.source_mapped === false;
                });
                for (_i = 0, _len = warnings.length; _i < _len; _i++) {
                  warning = warnings[_i];
                  type = warning.source_mapped === true ? 'S' : 'C';
                  log.warn(warning.message + ' - ' + type + '[' + warning.line + ', ' + warning.column + ']: ' + warning.code);
                }
                legend = warnings.length !== 0 ? 'S: source, C: compiled' : '';
                log.debug('code analysis: done! [warnings: ' + warnings.length + '] ' + legend);
              }
              return back();
            });
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (config.compression.enabled === false) {
              return back();
            }
            if (!_.has(api.compress, output.extension)) {
              return back();
            }
            return api.compress[output.extension]({
              file: output.file,
              code: output.code,
              source_map: source_map.is_enabled() ? source_map.code : void 0,
              options: config.compression[output.extension] || {}
            }, function(err, result) {
              var saved, warning, _i, _len, _ref2;
              if (err) {
                failed = true;
                log.error(err.message);
                log.trace(err.stack);
                log.error('compression: FAILED!');
              } else {
                saved = 100 - Math.round((result.code.length * 100) / output.code.length);
                output.code = result.code;
                source_map.code = result.source_map;
                _ref2 = result.warnings;
                for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                  warning = _ref2[_i];
                  log.warn(warning);
                }
                log.debug('compression: done! [warnings: ' + result.warnings.length + ', saved: ' + saved + '% ]');
              }
              return back();
            });
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (source_map.is_enabled() && _.has(source_map.code, 'mappings')) {
              output.code += '\n' + source_map.link;
            }
            return async.series([
              function(back) {
                return fs_tools.mkdir(output.directory, back);
              }, function(back) {
                return fs.writeFile(output.file, output.code, {
                  encoding: output.encoding
                }, back);
              }
            ], function(err) {
              if (err) {
                failed = true;
                log.error(err.message);
                log.trace(err.stack);
                log.error('writing output file: FAILED!');
              }
              return back();
            });
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (!source_map.is_enabled()) {
              return back();
            }
            if (!_.has(source_map.code, 'mappings')) {
              return back();
            }
            source_map.code = JSON.stringify(source_map.code, null, 4);
            return async.series([
              function(back) {
                return fs_tools.mkdir(source_map.directory, back);
              }, function(back) {
                return fs.writeFile(source_map.file, source_map.code, back);
              }
            ], function(err) {
              if (err) {
                failed = failed;
                log.error(err.message);
                log.trace(err.stack);
                log.warn('source mapping: FAILED!');
              } else {
                log.debug('source mapping: done!');
              }
              return back();
            });
          }, function(back) {
            if (failed === true) {
              return back();
            }
            if (!cache.is_enabled()) {
              return back();
            }
            return async.series([
              function(back) {
                return fs_tools.mkdir(cache.directory, back);
              }, function(back) {
                return fs.writeFile(cache.file, cache.code, back);
              }
            ], function(err) {
              if (err) {
                failed = failed;
                log.error(err.message);
                log.trace(err.stack);
                log.warn('caching: FAILED!');
              }
              return back();
            });
          }, function(back) {
            if (failed === true) {
              batch.failures++;
              log.error('processing file: FAILED!\n');
            } else {
              batch.successes++;
              log.info('processing file: done!\n');
            }
            log.flush();
            batch.ended = Date.now();
            batch.duration = ((batch.ended - batch.started) / 1000) + 's';
            return back();
          }
        ], next);
      }, function() {
        logger.info('*** processing project: done! ***');
        logger.debug('[duration: ' + batch.duration + ', processed: ' + batch.processed + ', skipped: ' + batch.skipped + ', successes: ' + batch.successes + ', failures: ' + batch.failures + ']');
        if (back) {
          return back(null, {
            processed: batch.processed,
            skipped: batch.skipped,
            successes: batch.successes,
            failures: batch.failures
          });
        }
      });
    } catch (_error) {
      err = _error;
      if (back) {
        return back(err);
      } else {
        return console.error(err);
      }
    }
  };

}).call(this);

//# sourceMappingURL=continuum.map
