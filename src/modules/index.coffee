'use strict'

debug = require('debug')('trampoline:index')
_     = require 'underscore'
co    = require 'co'

module.exports = co (body) -->
    debug 'got a request %j', body
