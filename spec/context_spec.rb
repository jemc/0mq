
require 'spec_helper'


describe ZMQ::Context do
  
  its(:pointer) { should be_a FFI::Pointer }
  its(:to_ptr)  { should be_a FFI::Pointer }
  
  around { |test| Timeout.timeout(1) {test.run} } # Timeout after 1 second
  
  
  it "can terminate the context" do
    subject.terminate
    subject.pointer.should eq nil
    expect { subject.socket ZMQ::ROUTER }.to raise_error SystemCallError
  end
  
  it "can create a socket within the given context" do
    socket = subject.socket ZMQ::ROUTER
    
    socket.should be_a ZMQ::Socket
    socket.type.should eq ZMQ::ROUTER
    socket.context.should be subject
  end
  
  describe ZMQ::DefaultContext do
    it { should be_a ZMQ::Context }
  end
  
end
