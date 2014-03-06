
require 'spec_helper'

describe ZMQ::Curve do
  
  it "can generate a keypair" do
    pending 'Unsupported in libzmq < 4' if ZMQ.version < 4
    
    keypair = ZMQ::Curve.keypair
    keypair[:public].size.should eq  40
    keypair[:private].size.should eq 40
  end
  
end
