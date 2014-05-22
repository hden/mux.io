'use strict'

app = require 'commander'

app
.version(require("#{__dirname}/../package.json").version or '0.0.1')
.option('-h, --host [hostname]', 'Hostname')
.option('-w, --ws   [8000]', 'Websocket port', parseInt)
.option('-p, --port [80]', 'Port', parseInt)
.option('-n, --nsq  [nsqd]', 'nsqd http address')
.parse(process.argv)

require("#{__dirname}/../lib/main")(app)
