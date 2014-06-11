'use strict'

debug  = require('debug')('mux:main')
patch  = require 'socketio-wildcard'
_      = require 'underscore'
parse  = require 'co-body'
nsq    = require 'nsq.js'

###
io    = require('socket.io')()
mount = require('koa-mount')
mux   = require('mux.io')()
app   = require('koa')()

# Standard
mux.createHTTPServer().listen()
mux.createWSServer(io)

# Namespace
nsp   = '/mux'

mux.createWSServer(io.of(nsp))
app.use(mount(nsp, mux.createHTTPServer()))
app.listen()
###

passthrough = (d) ->
  d

module.exports = (options = {}, fn = passthrough) ->
  if options.nsq?
    debug 'options %j', options
    writer = nsq.writer(options.nsq)

  nsp =
    connected: {}

  _.defaults options, {
    hostname: require('os').hostname()
    port: 8000
  }

  createHTTPServer = ->
    app = require('koa')()

    # body parser
    app.use (next) -->
      @request.body ?= yield parse(@)
      yield next

    app.use(require('koa-trie-router')(app))

    # general message handler
    app.post '/:socketId', (next) -->
      return unless nsp.connected[@params.socketId]? and (@query.topic?)
      @body  = 'ok'
      socket = nsp.connected[@params.socketId]
      return unless @request.body?
      socket.emit(@query.topic, @request.body)

    # ack message handler
    app.post '/:socketId/:messageId', (next) -->
      return unless nsp.connected[@params.socketId]?
      @body  = 'ok'
      socket = nsp.connected[@params.socketId]
      return unless @request.body?
      # emitting ack packet
      socket.ack(@params.messageId)(@request.body)

      yield next

  createWSServer = (namespace, fn = passthrough) ->
    nsp = if namespace.sockets? then namespace.sockets else namespace
    nsp.use (socket, next) ->
      debug 'got connection from %s', socket.id
      next()
    nsp.use(patch())

    debug 'attached to namespace %s', nsp.name or '/'

    nsp.on 'connection', (socket) ->
      debug 'on connection'

      socket.on '*', (packet) ->
        debug 'on message'

        if packet.id?
          # client expects ack
          packet = _.clone packet
          packet.replyTo = "http://#{options.hostname}:#{options.port}#{nsp.name}#{socket.id}/#{packet.id}"

        topic = packet?.data?[0]

        if options.nsq? and topic?
          debug 'bouncing topic:%s packet: %j', topic, packet
          writer.publish(topic, fn(packet))

    namespace

  {createWSServer, createHTTPServer}
