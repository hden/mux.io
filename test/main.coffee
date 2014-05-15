'use strict'

debug    = require('debug')('trampoline:test')
io       = require 'socket.io-client'
request  = require 'superagent'
nsq      = require 'nsq.js'
{assert} = require 'chai'

HOSTNAME = 'localhost'
HTTPPORT = 8080
WSPORT   = 8000

describe 'trampoline', ->
  socket = undefined
  reader = undefined

  before (done) ->
    require("#{__dirname}/../lib/main")({hostname: HOSTNAME, wsport:WSPORT, httpport: HTTPPORT, nsq: ':4150'})

    socket = io.connect "http://#{HOSTNAME}:#{WSPORT}/"

    socket.on 'error', (error) ->
      console.error error.stack

    socket.once 'connect_error', done
    socket.once 'connect', done

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
    payload =
      bar: 'baz'

    reader.once 'message', (message) ->
      message.finish()
      msg = message.json()

      assert.equal msg.name, 'foo'
      assert.deepEqual msg.args, [payload]
      assert.isString msg.replyTo
      do done

    socket.emit 'foo', payload, done

  it 'should bounce back ack message', (done) ->
    @timeout 10 * 1000
    payload =
      baz: 'nyan'

    reader.once 'message', (message) ->
      message.finish()
      {replyTo} = message.json()

      request
      .post(replyTo)
      .send(payload)
      .end (res) ->
        done 'faild to post message' unless res.ok

    socket.emit 'foo', (ack) ->
      assert.deepEqual ack, payload
      do done

  it 'should be able to send specific message'
