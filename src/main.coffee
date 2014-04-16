'use strict'

fs      = require 'fs'

debug   = require('debug')('trampoline:main')
app     = require('koa')()

_       = require 'underscore'
program = require 'commander'
parse   = require 'co-body'
raven   = require 'raven'

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
    try
        @request.body = yield parse @
    catch e
        debug 'error parsing body %s', e.message
        throw e if e.status isnt 415
    yield next

# router
existsSync = _.memoize fs.existsSync

app.use (next) -->
    modulePath = "#{__dirname}/modules#{@request.path}.js"
    return @throw 404 unless existsSync modulePath

    try
        require(modulePath)(@request.body, @request.query)
    catch e
        debug 'error while processing message: %s', e.message

    @body = 'OK'
    yield next

app.listen program.port or 8000
