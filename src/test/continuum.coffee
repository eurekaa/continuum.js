# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: index
# Created: 22/07/14 11.04

js_test = require 'jstest'
expect = require('chai').expect
fs = require 'fs'
fs_tools = require 'fs-tools' 
path = require 'path'
async = require 'async'
_ = require 'lodash'
continuum = require '../continuum.js'
examples = require './examples.js'
options = continuum.setup examples.options

js_test.Test.describe 'continuum.js', ->

   @.describe '.info()', ->
      @.it 'provides correct informations.', ->
         info = continuum.info()
         pack = require '../../package.json'
         expect(info.version).to.be.equal pack.version
         expect(info.author).to.be.equal pack.author
   
   @.describe '.run()', ->
      
      # (if test starts means that continuum runned without errors).
      @.it 'processes all files without errors.', -> expect(null).to.be.null

      @.it 'reads file content.', (done)->
         fs.readFile options.input.path + '/media/not_compilable.txt', 'utf-8', (err, content)->
            expect(err).to.be.null
            expect(content).not.to.be.empty
            done()

      @.it 'copies file from input to output creating sub directories if needed.', ->
         expect(fs.existsSync(options.output.path + '/media/not_compilable.txt')).to.be.true

      @.it 'writes file to output  creating sub directories if needed.', ->
         expect(fs.existsSync(options.output.path + '/scripts/coffeescript/cps_none.js')).to.be.true

      @.it 'if cache is enabled compiles only modified files.', (done)->
         #todo: esegui run() con un solo file e verifica che non sia compilato
         #todo: riscrivi il sorgente di un file, compilalo e controlla che sia compilato.
         done()
      
      @.it 'writes cache file creating sub directories if needed.', (done)->
         fs_tools.walk options.input.path, (file_path, stats, next)->
            cache_path = file_path.replace(options.input.path, options.cache.path).replace(path.extname(file_path), options.cache.extension)
            expect(fs.existsSync(cache_path)).to.be.true
            next()
         , done
      
      @.it 'writes logs.', (done)->
         fs.exists options.log.path + '\\' + options.log.name + options.log.extension, (exists)->
            expect(exists).to.be.true
            done()

