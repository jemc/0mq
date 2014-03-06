
require 'spec_helper'

describe ZMQ::Curve do
  
  it "can generate a keypair" do
    keypair = ZMQ::Curve.keypair
    keypair[:public].size.should eq  40
    keypair[:private].size.should eq 40
  end
  
end
