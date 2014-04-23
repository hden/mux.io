'use strict'

app = require 'commander'

app
.version(require("#{__dirname}/../package.json").version or '0.0.1')
.option('-h, --host [hostname]', 'Hostname')
.option('-p, --port [8000]', 'Port', parseInt)
.option('-n, --nsq  [nsqd]', 'nsqd http address')
.parse(process.argv)

require("#{__dirname}/../lib/trampoline")(app)
