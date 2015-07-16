# Company: Eureka²
# Developer: Stefano Graziato
# Email: stefano.graziato@eurekaa.it
# Homepage: http://www.eurekaa.it
# GitHub: https://github.com/eurekaa

# File Name: test
# Created: 06/07/2015 18:25

name: 'json'
author:
   name: 'stefano graziato'
   email: 'stefano.graziato@eurekaa.it'
type: 'function'
async: true
arguments:
   input:
      type: object
      required: true
      properties:
         file:
            type: 'string', required: true
         source_map:
            type: 'object', required: false
         code:
            type: 'string', required: false
   back:
      type: 'function', required: true
returns:
   type: 'object'
   properties:
      code:
         type: 'string'
      source_map:
         type: 'object'
      warnings:
         type: 'array'