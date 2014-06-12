
require 'spec_helper'


describe ZMQ::Socket do
  
  subject { ZMQ::Socket.new type }
  let(:type) { ZMQ::SUB }
  let(:socket_path) { 'ipc:///tmp/test' }
  
  let!(:pull_sock) { ZMQ::Socket.new(ZMQ::PULL).tap{|s| s.bind    'ipc:///tmp/pp'} }
  let!(:push_sock) { ZMQ::Socket.new(ZMQ::PUSH).tap{|s| s.connect 'ipc:///tmp/pp'} }
  
  let!(:req_sock)  { ZMQ::Socket.new(ZMQ::REQ)   .tap{|s| s.bind    'ipc:///tmp/r1'} }
  let!(:rtr_sockp) { ZMQ::Socket.new(ZMQ::ROUTER).tap{|s| s.connect 'ipc:///tmp/r1'} }
  let!(:dlr_sockp) { ZMQ::Socket.new(ZMQ::DEALER).tap{|s| s.bind    'ipc:///tmp/r2'} }
  let!(:rtr_sock)  { ZMQ::Socket.new(ZMQ::ROUTER).tap{|s| s.connect 'ipc:///tmp/r2'} }
  let(:proxy) { ZMQ::Proxy.new rtr_sockp, dlr_sockp }
  let(:proxy_thread) { Thread.new { proxy.run } }
  
  its(:pointer) { should be_a FFI::Pointer }
  its(:to_ptr)  { should be_a FFI::Pointer }
  its(:context) { should eq ZMQ::DefaultContext }
  its(:type) { should eq ZMQ::SUB }
  its(:type_sym) { should eq :SUB }
  
  after {
    pull_sock.tap { |s| s.close unless s.closed? }
    push_sock.tap { |s| s.close unless s.closed? }
    req_sock .tap { |s| s.close unless s.closed? }
    rtr_sockp.tap { |s| s.close unless s.closed? }
    dlr_sockp.tap { |s| s.close unless s.closed? }
    rtr_sock .tap { |s| s.close unless s.closed? }
  }
  
  around { |test| Timeout.timeout(5) { test.run } }
  
  
  it "can bind to an endpoint" do
    subject.bind socket_path
  end
  
  it "will raise on a bad call to bind" do
    expect { subject.bind 'huh?://nope' }.to raise_error SystemCallError
  end
  
  it "can unbind from an endpoint" do
    subject.bind   socket_path
    subject.unbind socket_path
  end
  
  it "will raise on a bad call to unbind" do
    expect { subject.unbind socket_path }.to raise_error SystemCallError
  end
  
  it "can connect to an endpoint" do
    subject.connect socket_path
  end
  
  it "will raise on a bad call to connect" do
    expect { subject.connect 'huh?://?' }.to raise_error SystemCallError
  end
  
  it "can disconnect from an endpoint" do
    subject.connect    socket_path
    subject.disconnect socket_path
  end
  
  it "will raise on a bad call to disconnect" do
    expect { subject.disconnect socket_path }.to raise_error SystemCallError
  end
  
  it "can get and set int socket options" do
    subject.get_opt(ZMQ::BACKLOG).should eq 100 # Default value
    subject.set_opt ZMQ::BACKLOG,           99
    subject.get_opt(ZMQ::BACKLOG).should eq 99
    subject.backlog              .should eq 99
    subject.backlog =                       100
    subject.backlog              .should eq 100
  end
  
  it "can get and set int64 socket options" do
    subject.get_opt(ZMQ::MAXMSGSIZE).should eq -1 # Default value
    subject.set_opt ZMQ::MAXMSGSIZE,           0x7FFFFFFFFFFFFFFF
    subject.get_opt(ZMQ::MAXMSGSIZE).should eq 0x7FFFFFFFFFFFFFFF
    subject.maxmsgsize              .should eq 0x7FFFFFFFFFFFFFFF
    subject.maxmsgsize =                       -1
    subject.maxmsgsize              .should eq -1
  end
  
  it "can get and set uint64 socket options" do
    subject.get_opt(ZMQ::AFFINITY).should eq 0 # Default value
    subject.set_opt ZMQ::AFFINITY,           0xFFFFFFFFFFFFFFFF
    subject.get_opt(ZMQ::AFFINITY).should eq 0xFFFFFFFFFFFFFFFF
    subject.affinity              .should eq 0xFFFFFFFFFFFFFFFF
    subject.affinity =                       0
    subject.affinity              .should eq 0
  end
  
  it "can get and set bool socket options" do
    subject.get_opt(ZMQ::IMMEDIATE).should eq false # Default value
    subject.set_opt ZMQ::IMMEDIATE,           true
    subject.get_opt(ZMQ::IMMEDIATE).should eq true
    subject.immediate              .should eq true
    subject.immediate =                       false
    subject.immediate              .should eq false
  end
  
  it "can set string socket options" do
    subject.set_opt ZMQ::SUBSCRIBE,   'topic.name'
    subject.subscribe           'other.topic.name'
    subject.set_opt ZMQ::UNSUBSCRIBE, 'topic.name'
    subject.unsubscribe         'other.topic.name'
  end
  
  it "can get string socket options" do
    subject.bind socket_path
    subject.get_opt(ZMQ::LAST_ENDPOINT).should eq socket_path
    subject.last_endpoint              .should eq socket_path
  end
  
  it "will raise on a bad call to set_opt" do
    expect { subject.set_opt ZMQ::IDENTITY, "" }.to \
      raise_error SystemCallError # socket identity cannot be empty
  end
  
  it "can close itself" do
    subject.close
    subject.pointer.should eq nil
    expect { subject.get_opt ZMQ::AFFINITY }.to raise_error SystemCallError
  end
  
  specify(:closed?) {
    subject.closed?.should eq false
    subject.close
    subject.closed?.should eq true
  }
  
  specify "binding or connecting a closed socket raises an exception" do
    subject.close
    expect { subject.bind socket_path }.to raise_error Errno::ENOTSOCK
    expect { subject.connect socket_path }.to raise_error Errno::ENOTSOCK
  end
  
  it "sets up a closing finalizer for the socket pointer" do
    socket = nil
    finalizer = nil
    ObjectSpace.should_receive :define_finalizer do |obj, proc|
      socket = obj
      finalizer = proc
    end
    
    ZMQ::Socket.new(ZMQ::PULL)#.should eq socket
    
    LibZMQ.should_receive(:zmq_close).with(socket.pointer)
          .exactly(:once).and_call_original
    finalizer.call
    
    # Verify message expectations and clear out to original implementations
    # so that the method calls in the after block go through and prevent lockup
    RSpec::Mocks.verify
    RSpec::Mocks.teardown
  end
  
  it "can send and receive strings" do
    push_sock.send_string 'testA1', ZMQ::SNDMORE
    push_sock.send_string 'testA2'
    push_sock.send_string 'testB'
    
    pull_sock.recv_string.should eq 'testA1'
    pull_sock.get_opt(ZMQ::RCVMORE).should eq true
    pull_sock.recv_string.should eq 'testA2'
    pull_sock.get_opt(ZMQ::RCVMORE).should eq false
    pull_sock.recv_string.should eq 'testB'
    pull_sock.get_opt(ZMQ::RCVMORE).should eq false
  end
  
  it "will do a string conversion if the message is not a string" do
    data = Object.new.tap {|obj|
      obj.instance_eval { def to_s; "string"; end }
    }
    
    push_sock.send_string           data
    pull_sock.recv_string.should eq data.to_s
  end
  
  it "can send and receive multipart messages as arrays" do
    push_sock.send_array           ['testA1', 'testA2']
    pull_sock.recv_array.should eq ['testA1', 'testA2']
  end
  
  it "can pass flags to send_array and recv_array" do
    i = 0
    push_sock.should_receive(:send_string).twice { |*args|
      args.should eq (i==0 ? ['testA1', ZMQ::SNDMORE|ZMQ::DONTWAIT] : 
                             ['testA2', ZMQ::DONTWAIT]); i+= 1
    }
    push_sock.send_array ['testA1', 'testA2'], ZMQ::DONTWAIT
    
    pull_sock.should_receive(:recv_string).with(ZMQ::DONTWAIT)
    pull_sock.recv_array ZMQ::DONTWAIT
  end
  
  it "will do an array conversion if the multipart message is not an array" do
    data = Object.new.tap {|obj|
      obj.instance_eval { def to_a; ["part1","part2","part3"]; end }
    }
    
    push_sock.send_array           data
    pull_sock.recv_array.should eq data.to_a
  end
  
  it "will do both array and string conversion when necessary" do
    data = Object.new.tap {|obj|
      obj.instance_eval { def to_a; [1,2,3,4]; end }
    }
    
    push_sock.send_array           data
    pull_sock.recv_array.should eq data.to_a.map {|i| i.to_s }
  end
  
  it "can receive multipart messages with separated routing info" do
    proxy_thread
    result = nil
    
    thr = Thread.new { req_sock.send_array ['test', 'body']
                       result = req_sock.recv_array }
    
    routing, body = rtr_sock.recv_with_routing
    routing.count.should eq 2
    body.should eq ['test', 'body']
    
    rtr_sock.send_array [*routing, '', 'resulting', 'reply']
    thr.join
    result.should eq ['resulting', 'reply']
    
    proxy_thread.kill
  end
  
  it "can send multipart messages with separated routing info" do
    proxy_thread
    result = nil
    
    thr = Thread.new { req_sock.send_array ['test', 'body']
                       result = req_sock.recv_array }
    
    rt1, rt2, delim, *body = rtr_sock.recv_array
    routing = [rt1, rt2]
    delim.should eq ''
    body.should eq ['test', 'body']
    
    rtr_sock.send_with_routing routing, ['resulting', 'reply']
    thr.join
    result.should eq ['resulting', 'reply']
    
    proxy_thread.kill
  end
  
end
