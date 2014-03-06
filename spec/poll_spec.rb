
require 'spec_helper'


describe ZMQ::Poll do
  
  subject { ZMQ::Poll.new pull_socket }
  
  let!(:push_socket) {
    ZMQ::Socket.new(ZMQ::PUSH).tap do |s|
      s.bind 'ipc://poll_conn.ipc'
    end
  }
  
  let!(:pull_socket) {
    ZMQ::Socket.new(ZMQ::PULL).tap do |s|
      s.connect 'ipc://poll_conn.ipc'
    end
  }
  
  after { File.delete 'poll_conn.ipc' if File.exists? 'poll_conn.ipc' }
  
  around { |test| Timeout.timeout(0.25) {test.run} }
  
  
  def make_pull
    ZMQ::Socket.new(ZMQ::PULL).tap do |s|
      s.connect 'ipc://poll_conn.ipc'
    end
  end
  
  
  context "initializer socket args:" do
    
    it "raises an error if no sockets are provided" do
      expect {ZMQ::Poll.new().tap { |p| p.run.should eq {} } }
        .to raise_error ArgumentError
    end
    
    it "can accept a single socket with no event flags" do
      push_socket.send_string 'test'
      sleep 0.01
      
      ZMQ::Poll.new(pull_socket).tap { |p|
        value = {pull_socket => ZMQ::POLLIN}
        p.run.should eq value
      }
    end
    
    it "can accept multiple sockets with no event flags" do
      pull2 = make_pull
      sleep 0.01
      
      push_socket.send_string 'test'
      push_socket.send_string 'test'
      sleep 0.01
      
      ZMQ::Poll.new(pull_socket, pull2).tap { |p|
        p.run.count.should eq 2
      }
    end
    
    it "can accept a single socket with an event flag" do
      ZMQ::Poll.new(push_socket => ZMQ::POLLOUT).tap { |p|
        value = {push_socket => ZMQ::POLLOUT}
        p.run.should eq value
      }
    end
    
    it "can accept multiple sockets with event flags" do
      push2 = ZMQ::Socket.new(ZMQ::PUSH).tap {|s| s.connect 'ipc://poll_conn.ipc' }
      sleep 0.01
      
      ZMQ::Poll.new(push_socket => ZMQ::POLLOUT, push2 => ZMQ::POLLOUT)
        .tap { |p| p.run.count.should eq 2 }
    end
    
    it "can accept multiple sockets with and without event flags" do
      pull2 = make_pull
      sleep 0.01
      
      push_socket.send_string 'test'
      push_socket.send_string 'test'
      sleep 0.01
      
      ZMQ::Poll.new(pull_socket, pull2, push_socket => ZMQ::POLLOUT)
        .tap { |p| p.run.count.should eq 3 }
    end
    
  end
  
  context "initializer options:" do
    
    context "timeout:" do
      
      it "blocks indefinitely on timeout = -1" do
        expect {
          Timeout.timeout(0.1) { ZMQ::Poll.new(pull_socket, timeout: -1).run }
        }.to raise_error Timeout::Error
      end
      
      it "returns immediately on timeout = 0" do
        expect {
          Timeout.timeout(0.1) { ZMQ::Poll.new(pull_socket, timeout: 0).run }
        }.to_not raise_error
      end
      
      it "returns after timeout expiration" do
        expect {
          Timeout.timeout(0.1) { ZMQ::Poll.new(pull_socket, timeout: 0.01).run }
        }.to_not raise_error
      end
      
      it "implementes run_nonblock" do
        expect {
          Timeout.timeout(0.1) { ZMQ::Poll.new(pull_socket).run_nonblock }
        }.to_not raise_error
      end
      
      it "implements poll_nonblock" do
        expect {
          Timeout.timeout(0.1) { ZMQ::Poll.poll_nonblock pull_socket }
        }.to_not raise_error
      end
      
    end
    
  end
  
  
  context "return values:" do
    
    it "returns a hash of sockets ready for IO" do
      pull2 = make_pull
      sleep 0.01
      
      push_socket.send_string 'test'
      push_socket.send_string 'test'
      sleep 0.01
      
      results = ZMQ::Poll.new(pull_socket, pull2, push_socket => ZMQ::POLLOUT).run
      
      results.count.should eq 3
      results[pull_socket].should eq ZMQ::POLLIN
      results[pull2].should eq ZMQ::POLLIN
      results[push_socket].should eq ZMQ::POLLOUT
    end
    
    it "passes sockets ready for IO to a block" do
      pull2 = make_pull
      sleep 0.01
      
      push_socket.send_string 'test'
      push_socket.send_string 'test'
      sleep 0.01
      
      results = {}
      ZMQ::Poll.new(pull_socket, pull2, push_socket => ZMQ::POLLOUT)
        .run do |socket, events|
          results[socket] = events
        end
      
      results.count.should eq 3
      results[pull_socket].should eq ZMQ::POLLIN
      results[pull2].should eq ZMQ::POLLIN
      results[push_socket].should eq ZMQ::POLLOUT
    end
    
  end
  
  
  context "class poll method:" do
    
    subject { ZMQ::Poll }
    
    it { should respond_to :poll }
    it { should respond_to :poll_nonblock }
    
    it "polls a socket" do
      push_socket.send_string 'test'
      sleep 0.01
      
      subject.poll(pull_socket).count.should eq 1
    end
    
  end
  
end
