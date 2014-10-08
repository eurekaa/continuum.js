// Generated by CoffeeScript 1.7.1
(function() {
  var async, continuum, examples, expect, fs, fs_tools, js_test, options, path, _;

  js_test = require('jstest');

  expect = require('chai').expect;

  fs = require('fs');

  fs_tools = require('fs-tools');

  path = require('path');

  async = require('async');

  _ = require('lodash');

  continuum = require('../continuum.js');

  examples = require('./examples.js');

  options = continuum.setup(examples.options);

  js_test.Test.describe('continuum.js', function() {
    this.describe('.info()', function() {
      return this.it('provides correct informations.', function() {
        var info, pack;
        info = continuum.info();
        pack = require('../../package.json');
        expect(info.version).to.be.equal(pack.version);
        return expect(info.author).to.be.equal(pack.author);
      });
    });
    return this.describe('.run()', function() {
      this.it('processes all files without errors.', function() {
        return expect(null).to.be["null"];
      });
      this.it('reads file content.', function(done) {
        return fs.readFile(options.input.path + '/media/not_compilable.txt', 'utf-8', function(err, content) {
          expect(err).to.be["null"];
          expect(content).not.to.be.empty;
          return done();
        });
      });
      this.it('copies file from input to output creating sub directories if needed.', function() {
        return expect(fs.existsSync(options.output.path + '/media/not_compilable.txt')).to.be["true"];
      });
      this.it('writes file to output creating sub directories if needed.', function() {
        return expect(fs.existsSync(options.output.path + '/media/not_compilable.txt')).to.be["true"];
      });
      this.it('if cache is enabled compiles only modified files.', function(done) {
        return done();
      });
      this.it('writes cache file creating sub directories if needed.', function() {
        return expect(fs.existsSync(options.cache.path + '/media/not_compilable.cache')).to.be["true"];
      });
      return this.it('writes logs.', function(done) {
        return fs.exists(options.log.path + '\\' + options.log.name + '.' + options.log.extension, function(exists) {
          expect(exists).to.be["true"];
          return done();
        });
      });
    });
  });

}).call(this);

//# sourceMappingURL=continuum.map