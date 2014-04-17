'use strict'

fs        = require 'fs'

debug     = require('debug')('trampoline:main')
app       = require('koa')()

multipart = require 'co-multipart'
_         = require 'underscore'
program   = require 'commander'
parse     = require 'co-body'
raven     = require 'raven'

# option parsing
program
.version(require("#{__dirname}/../package.json").version or '0.0.1')
.option('-e --error [sentry]', 'error logging via sentry')
.option('-p --port <port>', 'a port to listen to', parseInt)
.parse(process.argv)

if program.error?
    client = new raven.Client program.error
    _.bindAll client, 'captureError', 'captureQuery', 'captureMessage'
    app.on 'error', client.captureError

app.on 'error', (error) ->
    console.error error.stack

# body-parser
app.use (next) -->

    if @is 'multipart/form-data'
        try
            parts = yield from multipart @
        catch e
            debug 'error parsing multipart body %s', e.message
            return debug 'request: %j', @request

        console.log 'got a multipart: %j', parts.files

        try
            yield next
        catch e
            do parts.dispose
            throw e

        do parts.dispose

    else
        try
            @request.body = yield parse @
        catch e
            debug 'error parsing body %s', e.message
            return debug 'request: %j', @request

        yield next

# router
existsSync = _.memoize fs.existsSync

app.use (next) -->
    modulePath = "#{__dirname}/modules#{@request.path}.js"
    return @throw 404 unless existsSync modulePath

    try
        require(modulePath)(@request.body, @request.query) if @request.body?
    catch e
        debug 'error while processing message: %s', e.message

    @body = 'OK'
    yield next

app.listen program.port or 8000
