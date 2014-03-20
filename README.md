# 0mq
_Works like ZeroMQ. Feels like Ruby._

[![Build Status](https://travis-ci.org/jemc/0mq.png)](https://travis-ci.org/jemc/0mq)
[![Gem Version](https://badge.fury.io/rb/0mq.png)](http://badge.fury.io/rb/0mq)

The 0mq gem is a Ruby wrapper for the ZeroMQ (libzmq) API. Built on ffi-rzmq-core, the bridge from Ruby to ZeroMQ’s C API, the 0mq gem conceals the interaction with FFI and exposes an interface that uses blocks, raises exceptions, and feels like the Ruby we love to use.

## Supported

Supported ZeroMQ (libzmq) versions:

- 3.x

- 4.x

Supported Ruby versions:

- MRI >= 1.9

- Rubinius 2.x

## Feature Requests / Bug Reports

File them as issues or pull requests on the [0mq github repository](https://github.com/jemc/0mq).

## Authors

- Joe McIlvain

- Alex McLain

## Installation / Prerequisites

- Requires the [libzmq library](http://zeromq.org/intro:get-the-software).

- PGM (multicast) requires compiling libzmq with ./configure --with-pgm

- Curve cryptography requires compiling libzmq with [libsodium](https://github.com/jedisct1/libsodium).
	
## ZeroMQ Documentation

- Manual: http://zeromq.org/intro:read-the-manual

- API: http://api.zeromq.org/

## Code Examples

### Using The 0mq Gem

``` ruby
require '0mq'
```

### Create A Socket

Sockets can be created by specifying the [ZMQ socket type](http://api.zeromq.org/4-0:zmq-socket). Any errors will be raised as exceptions.

``` ruby
socket = ZMQ::Socket.new ZMQ::PULL
socket.connect 'tcp://127.0.0.1:10000'
```

### Send And Receive Data

``` ruby
address = 'tcp://127.0.0.1:10000'

push = ZMQ::Socket.new ZMQ::PUSH
push.bind address

pull = ZMQ::Socket.new ZMQ::PULL
pull.connect address

push.send_string 'test'

string = pull.recv_string

puts string
```

### Poll A Socket For Data

``` ruby
address = 'inproc://poll_example'

pull = ZMQ::Socket.new ZMQ::PULL
pull.bind address

# Push a message after a delay.
Thread.new do
  push = ZMQ::Socket.new ZMQ::PUSH
  push.connect address
  sleep 3

  push.send_string 'test'
end

# Check if pull has any data (it doesn't yet).
# (Non-blocking demonstration.)
result = ZMQ::Poll.poll_nonblock pull
puts "No data available yet." if result.empty?

# Do a blocking poll until the pull socket has data.
ZMQ::Poll.poll pull do |socket, event|
  puts socket.recv_string
end
```

### Proxy Sockets

A proxy can be used to funnel multiple endpoints into a single connection.
See: [Pub-Sub Network with a Proxy](http://zguide.zeromq.org/page:all#The-Dynamic-Discovery-Problem)

```ruby
# ----------------     ----------------     ----------------     ----------------
# | Endpoint REQ | --> | Proxy ROUTER | --> | Proxy DEALER | --> | Endpoint REP |
# ----------------     ----------------     ----------------     ----------------

# Create sockets.
endpoint_req = ZMQ::Socket.new(ZMQ::REQ).tap    { |s| s.bind    'inproc://proxy_in'  }
proxy_router = ZMQ::Socket.new(ZMQ::ROUTER).tap { |s| s.connect 'inproc://proxy_in'  }
proxy_dealer = ZMQ::Socket.new(ZMQ::DEALER).tap { |s| s.bind    'inproc://proxy_out' }
endpoint_rep = ZMQ::Socket.new(ZMQ::REP).tap    { |s| s.connect 'inproc://proxy_out' }

# Create the proxy.
Thread.new { ZMQ::Proxy.proxy proxy_router, proxy_dealer }

# Send a message.
endpoint_req.send_string 'test'

puts endpoint_rep.recv_string
```
