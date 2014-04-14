'use strict'

debug   = require('debug')('trampoline:index')
_       = require 'underscore'
request = require 'superagent'
moment  = require 'moment'
nsq     = require 'nsq.js'
co      = require 'co'

writer  = nsq.writer ':24150'

writer
.on 'error', (error) ->
    debug 'writer error %s', error.message
.on 'error response', (error) ->
    debug 'writer, nsq response error %s', error.message

module.exports = co (data, query) -->
    mh = data['message-headers']
    data['message-headers'] = JSON.parse(mh) if _.isString mh

    # forward to nsq
    writer.publish(query.type, data) if query.type?

    result =
        type: query.type or 'unknown'
        time: moment().toISOString()
        data: data
    agent = request 'post', 'http://127.0.0.1:1080/1.0/event/put'

    # to cube
    try
        yield agent.send([result]).end.bind(agent)
    catch e
        debug 'faild to post to cube with message: %s', e.message
