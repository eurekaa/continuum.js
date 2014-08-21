# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: index
# Created: 22/07/14 11.15


js_test = require 'jstest'
chai = require 'chai'
fs_tools = require 'fs-tools'
fs = require 'fs'
path = require 'path'
async = require 'async'
_ = require 'lodash'

continuum = require '../continuum.js'
api = require '../api.js'
examples = require './examples.js'  
options = examples.options


# create testing environment.
async.series [
   
   # create source directory.
   (back)-> fs_tools.mkdir options.input.path, back
   
   # create source files.
   (back)-> async.each _.keys(examples), (example, next)->
      if example is 'options' then return next()
      file_name = options.input.path + '\\' + example + examples[example].extension
      async.series [
         (back)-> fs_tools.mkdir path.dirname(file_name), back
         (back)-> fs.writeFile file_name, examples[example].content, back
      ], next
   , back
   
   # run continuum process.
   (back)-> continuum.run options, back
   
   # run tests.
   (back)->
      js_test.cache = false
      js_test.Test.ASSERTION_ERRORS.push chai.AssertionError
      js_test.load './continuum.js', './api.js', ->
         js_test.Test.autorun (runner)->
            runner.setReporter new js_test.Test.Reporters.Spec()
            runner.addReporter js_test.Test.Reporters.ExitStatus()
            runner.addReporter js_test.Test.Reporters.Error()
            back()

], (err)-> #if err then throw err
