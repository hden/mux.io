'use strict'

debug  = require('debug')('trampoline:main')
_      = require 'underscore'
parse  = require 'co-body'
app    = require('koa')()
nsq    = require 'nsq.js'

noop   = ->
patch  = (Server) ->
  # socket.io wildcard patch
  Server.Manager::onClientMessage = (id, packet) ->
    return unless @namespaces[packet.endpoint]
    @namespaces[packet.endpoint].handlePacket id, packet
    p = _.clone packet
    p.name = '*'
    p.args = _.pick packet, 'id', 'name', 'args'
    @namespaces[packet.endpoint].handlePacket id, p
  Server

ack = (socket, ackId, args) ->
  args = [args] unless _.isArray args
  socket.packet {
      type: 'ack'
      args: args
      ackId: ackId
  }

module.exports = (options = {}, configure = noop) ->
  _.defaults options, {
    hostname: require('os').hostname()
    port: 8000
  }

  socketPool = {}

  # body parser
  app.use (next) -->
    @request.body = yield parse(@)
    yield next

  app.use(require('koa-trie-router')(app))

  # general message handler
  app.post '/:socketId', (next) -->
    return unless (socketPool[@params.socketId] is true) and (@query.topic?)
    @body  = 'ok'
    return unless @request.body?
    io.sockets.socket(@params.socketId).emit(@query.topic, @request.body)

  # ack message handler
  app.post '/:socketId/:messageId', (next) -->
    return unless socketPool[@params.socketId] is true
    @body  = 'ok'

    return unless @request.body?
    # emitting ack packet
    ack(io.sockets.socket(@params.socketId), @params.messageId, @request.body)

    yield next

  server   = require('http').Server(app.callback())
  io       = patch(require('socket.io')).listen(server)
  # writer   = nsq.writer ':4150'

  io.configure ->
    configure io

  io.sockets.on 'connection', (socket) ->
    socketPool[socket.id] = true

    socket.on 'disconnect', ->
      socketPool[socket.id] = undefined

    socket.on '*', ({name, args, id}, done) ->
      debug 'on message'

      body =
        name: name
        id: id
        args: args
        replyTo: "http://#{options.hostname}:#{options.port}/#{socket.id}/#{id}"

      console.log body

      # writer.publish name, body

  # engine start
  server.listen(options.port)

do module.exports
