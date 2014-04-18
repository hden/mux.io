'use strict'

debug = require('debug')('trampoline:client')
io    = require 'socket.io-client'

socket = io.connect 'http://localhost:8000/'#, {secure : true}


socket.on 'error', (error) ->
  console.log 'error %s', error.message

socket.on 'connect_failed', ->
  console.log 'connect_failed'

socket.on 'message', (message) ->
  console.log 'got a message %j', message

socket.emit 'signal', ['topic', {bar: 'baz'}], (data) ->
  console.log 'got a response %j', data
