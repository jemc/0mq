
require 'spec_helper'


describe ZMQ::Socket do
  
  subject { ZMQ::Socket.new type }
  let(:type) { ZMQ::SUB }
  
  its(:ptr) { should be_a FFI::Pointer }
  its(:context) { should eq ZMQ::DefaultContext }
  its(:type) { should eq ZMQ::SUB }
  its(:type_sym) { should eq :SUB }
  
  it "can set a socket option with set_opt" do
    LibZMQ.should_receive(:zmq_setsockopt)
          .with(subject.ptr, ZMQ::SUBSCRIBE, 'topic', 5)
    ZMQ.should_receive(:error_check).with(true)
    
    subject.set_opt ZMQ::SUBSCRIBE, 'topic'
  end
  
end
