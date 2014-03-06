# 0mq

[![Build Status](https://travis-ci.org/jemc/0mq.png)](https://travis-ci.org/jemc/0mq)
[![Gem Version](https://badge.fury.io/rb/0mq.png)](http://badge.fury.io/rb/0mq)

A Ruby-like wrapper for ffi-rzmq-core (ZeroMQ)

## Supported

Supported ZeroMQ (libzmq) versions:

- 3.x

- 4.x

Supported Ruby versions:

- MRI >= 1.9

- Rubinius 2.x

## Feature Requests / Bug Reports

File them as issues or pull requests on [the github repository](https://github.com/jemc/0mq).

## Authors

- Joe McIlvain

- Alex McLain

## Installation / Prerequisites

- Requires the libzmq library: http://zeromq.org/intro:get-the-software

- PGM (multicast) requires compiling libzmq with ./configure --with-pgm

- Curve cryptography requires compiling libzmq with libsodium:
	https://github.com/jedisct1/libsodium
	
## ZeroMQ Documentation

- Manual: http://zeromq.org/intro:read-the-manual

- API: http://api.zeromq.org/