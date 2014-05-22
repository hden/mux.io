trampoline
==========

Bouncing your socket.io data to nsq. With RESTful reply-to endpoints.

[![Build Status](https://travis-ci.org/hden/mux.io.svg?branch=master)](https://travis-ci.org/hden/mux.io)

## Design

![Design](https://github.com/hden/trampoline/raw/master/doc/diagram.png)

## Requirement

* node.js `~v0.11.11`

## Installation

    npm install

## Usage

    npm start

## Develpoment

    ./node_modules/.bin/coffee -w -c -o lib/ src/
    DEBUG=* npm test
