
require_relative 'benchmark_helper'

transport = :tcp

conn_endpt = bind_endpt = nil
case transport
when :tcp
  conn_endpt = "tcp://0.0.0.0:5555"
  bind_endpt = "tcp://lo:5555"
when :ipc
  bind_endpt = conn_endpt = "ipc:///tmp/0mq_bm_send_rcv"
when :inproc
  bind_endpt = conn_endpt = "inproc://thing"
end


rep = ZMQ::Socket.new(ZMQ::REP).tap {|s| s.connect conn_endpt }
req = ZMQ::Socket.new(ZMQ::REQ).tap {|s| s.bind    bind_endpt }

req_array = ["foo", "bar", "baz", "foo", "bar", "baz"]
rep_array = ["FOO", "BAR", "BAZ", "FOO", "BAR", "BAZ"]


benchmark "send/receive array 10000 times", profile:false do
  [
    Thread.new { 10000.times { req.send_array req_array; req.recv_array } },
    Thread.new { 10000.times { rep.recv_array; rep.send_array rep_array } },
  ].each &:join
end
