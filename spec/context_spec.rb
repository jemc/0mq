
require 'spec_helper'


describe ZMQ::Context do
  
  its(:ptr) { should be_a FFI::Pointer }
  
  describe ZMQ::DefaultContext do
    it { should be_a ZMQ::Context }
  end
  
end
