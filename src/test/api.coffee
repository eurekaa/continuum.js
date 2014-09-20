# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: api
# Created: 22/07/14 19.23


js_test = require 'jstest'
expect = require('chai').expect
fs = require 'fs'     
fs_tools = require 'fs-tools' 
path = require 'path'
_ = require 'lodash'
async = require 'async'
continuum = require '../continuum.js'
api = require '../api.js'
examples = require './examples.js'
options = continuum.setup examples.options
languages = ['coffeescript', 'livescript', 'javascript']

js_test.Test.describe 'api.js', -> 
   
   @.describe '.compile()', ->
      ###
      @.it 'compiles coffescript files.', ->
         for example in _.keys examples when examples[example].extension is '.coffee'
            expect(fs.existsSync(options.output.path + '/' + example + '.js')).to.be.true
      
      @.it 'compiles livescript files.', ->
         for example in _.keys examples when examples[example].extension is '.ls'
            expect(fs.existsSync(options.output.path + '/' + example + '.js')).to.be.true
      
      @.it 'skips compilation for plain javascript files.', ->
         for example in _.keys examples when examples[example].extension is '.js'
            expect(fs.existsSync(options.output.path + '/' + example + '.js')).to.be.true

      @.it 'compiles less files.', ->
         for example in _.keys examples when examples[example].extension is '.less'
            expect(fs.existsSync(options.output.path + '/' + example + '.css')).to.be.true

      @.it 'compiles stylus files.', ->
         for example in _.keys examples when examples[example].extension is '.stylus'
            expect(fs.existsSync(options.output.path + '/' + example + '.css')).to.be.true

      @.it 'compiles jade files.', ->
         for example in _.keys examples when examples[example].extension is '.jade'
            expect(fs.existsSync(options.output.path + '/' + example + '.html')).to.be.true

      @.it 'skips compilation for non compilable files.', ->
         for example in _.keys examples when examples[example].extension is '.txt'
            expect(fs.existsSync(options.output.path + '/' + example + '.txt')).to.be.true
      ###
   
   @.describe '.transform()', ->
      
      @.it 'performs cps transformation correctly.', (done)->
         async.each languages, (language, next)->
            expect(fs.existsSync('./' + options.output.path + '/scripts/' + language + '/cps.js')).to.be.true
            test = require './' + options.output.path + '/scripts/' + language + '/cps.js'
            test.test (err, result)->
               expect(err).to.be.null
               expect(result).to.be.true
               next()
         , done
      
      @.it 'leaves the code as it is when cps is not used.', (done)->
         async.each languages, (language, next)->
            expect(fs.existsSync('./' + options.output.path + '/scripts/' + language + '/cps_none.js')).to.be.true
            test = require './' + options.output.path + '/scripts/' + language + '/cps_none.js'
            test.test (err, result)->
               expect(err).to.be.null
               expect(result).to.be.true
               next()
         , done
