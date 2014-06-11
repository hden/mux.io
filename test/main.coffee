'use strict'

debug    = require('debug')('mux:test')
io       = require 'socket.io-client'
sio      = require('socket.io')()
request  = require 'superagent'
nsq      = require 'nsq.js'
{assert} = require 'chai'

describe 'mux.io', ->
  socket   = undefined
  reader   = undefined
  socketId = undefined

  frontFacingPort = 8000
  backendPort     = 8080

  before ->

    # create server
    mux = require('../')({hostname: 'localhost', port: backendPort, nsq: ':4150'})
    mux.createHTTPServer().listen(backendPort)
    mux.createWSServer(sio).listen(frontFacingPort)
    sio.on 'connection', (s) ->
      debug 'socket id %s', s.id
      socketId = s.id

    socket = io.connect "http://localhost:#{frontFacingPort}/"

    socket.on 'error', (error) ->
      console.error error.stack

  beforeEach (done) ->
    reader = nsq.reader {
      nsqd: [':4150']
      topic: 'foo'
      channel: 'test'
    }

    reader.once 'ready', done
    reader.on 'error', (error) ->
      console.error error.stack

  afterEach (done) ->
    reader.close done

  it 'should bounce socket.io message to nsq', (done) ->

    reader.once 'message', (message) ->
      message.finish()
      packet = message.json()

      debug 'packet %j', packet

      assert.deepPropertyVal packet, 'data[0]', 'foo'
      assert.deepPropertyVal packet, 'data[1].bar', 'baz'
      assert.include packet.replyTo, "http://localhost:#{backendPort}/#{socketId}/#{packet.id}"
      do done

    socket.emit 'foo', {bar: 'baz'}, ->

  it 'should bounce back ack message', (done) ->
    payload =
      baz: 'nyan'

    reader.once 'message', (message) ->
      message.finish()
      {replyTo} = message.json()

      debug 'posting to %s', replyTo

      request
      .post(replyTo)
      .send(payload)
      .end (res) ->
        done 'faild to post message' unless res.ok

    socket.emit 'foo', (ack) ->
      assert.deepEqual ack, payload
      do done

  it 'should be able to send specific message', (done) ->
    payload =
      bar: 'baz'

    socket.on 'foo', (data) ->
      assert.deepEqual data, payload
      do done

    request
      .post("http://localhost:#{backendPort}/#{socketId}?topic=foo")
      .send(payload)
      .end (res) ->
        done 'faild to post message' unless res.ok
