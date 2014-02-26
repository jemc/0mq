
require 'spec_helper'


describe ZMQ::Socket do
  
  subject { ZMQ::Socket.new type }
  let(:type) { ZMQ::REQ }
  
  its(:ptr) { should be_a FFI::Pointer }
  its(:context) { should eq ZMQ::DefaultContext }
  
end
