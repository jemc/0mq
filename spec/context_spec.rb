
require 'spec_helper'


describe ZMQ::Context do
  
  its(:ptr) { should be_a FFI::Pointer }
  
  describe ZMQ::DefaultContext do
    it { should be_a ZMQ::Context }
  end
  
  it "can create a socket within the given context" do
    socket = subject.socket ZMQ::ROUTER
    socket.context.should be subject
  end
  
end
