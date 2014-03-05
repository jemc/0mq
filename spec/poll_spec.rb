
require 'spec_helper'


describe ZMQ::Poll do
  
  it "test" do
    # p = LibZMQ::PollItem.new
    # p = ZMQ::Poll.poll Object.new, Object.new, Object.new
    # p = ZMQ::Poll.poll Object.new => ZMQ::POLLIN, Object.new => ZMQ::POLLIN, Object.new => ZMQ::POLLOUT
    # p = ZMQ::Poll.poll Object.new, Object.new => ZMQ::POLLIN, Object.new => ZMQ::POLLOUT, timeout: 1
    p = ZMQ::Poll.poll \
      ZMQ::Socket.new(ZMQ::ROUTER),
      ZMQ::Socket.new(ZMQ::ROUTER) => ZMQ::POLLIN,
      ZMQ::Socket.new(ZMQ::ROUTER) => ZMQ::POLLOUT,
      timeout: 1
    # require 'pry'; binding.pry
  end
  
end
