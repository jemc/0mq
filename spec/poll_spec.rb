
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
      timeout: 1 do |socket, events|
        puts "socket: #{socket}\nevents:#{events}"
      end
    
    # s1 = ZMQ::Socket.new ZMQ::ROUTER
    # s2 = ZMQ::Socket.new ZMQ::ROUTER
    # s3 = ZMQ::Socket.new ZMQ::ROUTER
    
    # s1.bind 'ipc://test1.ipc'
    # s2.bind 'ipc://test2.ipc'
    # s3.bind 'ipc://test3.ipc'
    
    # result = ZMQ::Poll.poll \
    #   s1,
    #   s2 => ZMQ::POLLIN,
    #   s3 => ZMQ::POLLOUT,
    #   timeout: 1
    
    # require 'pry'; binding.pry
  end
  
end
