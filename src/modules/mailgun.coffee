'use strict'

debug   = require('debug')('trampoline:index')
_       = require 'underscore'
request = require 'superagent'
moment  = require 'moment'
co      = require 'co'

module.exports = co (data, query) -->
    mh = data['message-headers']
    data['message-headers'] = JSON.parse(mh) if _.isString mh
    result =
        type: query.type or 'unknown'
        time: moment().toISOString()
        data: data
    debug 'got a request %j', result
    agent = request 'post', 'http:/localhost:1080/1.0/event/put'

    try
        yield agent.send([result]).end.bind(agent)
    catch e
        debug 'faild to post to cube with message: %s', e.message
