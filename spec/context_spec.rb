
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
    socket.context.should eq subject
  end
  
  it "sets up a terminating finalizer for the context pointer" do
    context = nil
    finalizer = nil
    ObjectSpace.should_receive :define_finalizer do |obj, proc|
      context = obj
      finalizer = proc
    end
    
    ZMQ::Context.new.should eq context
    
    term_meth = LibZMQ.respond_to?(:zmq_ctx_term) ? :zmq_ctx_term : :zmq_term
    LibZMQ.should_receive(term_meth).with(context.pointer)
          .exactly(:once).and_call_original
    finalizer.call
  end
  
  describe ZMQ::DefaultContext do
    it { should be_a ZMQ::Context }
  end
  
end
