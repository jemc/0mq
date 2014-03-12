
require 'spec_helper'

require 'poll_shared'


describe ZMQ::Poll do
  
  let(:poll_class) { ZMQ::Poll }
  
  it_behaves_like "a poll class"
  
  it "raises an error if no sockets are provided" do
    expect { poll_class.new().tap { |p| p.run.should eq {} } }
      .to raise_error ArgumentError
  end
end
