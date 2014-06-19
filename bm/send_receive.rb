
require_relative 'benchmark_helper'


req = ZMQ::Socket.new(ZMQ::REQ).tap {|s| s.connect 'ipc:///tmp/0mq_send_recv' }
rep = ZMQ::Socket.new(ZMQ::REP).tap {|s| s.bind    'ipc:///tmp/0mq_send_recv' }

req_array = ["foo", "bar", "baz", "foo", "bar", "baz"]
rep_array = ["FOO", "BAR", "BAZ", "FOO", "BAR", "BAZ"]


benchmark "send/receive array 1000 times", profile:true do
  [
    Thread.new { 1000.times { req.send_array req_array; req.recv_array } },
    Thread.new { 1000.times { rep.recv_array; rep.send_array rep_array } },
  ].each &:join
end
