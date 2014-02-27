
require 'spec_helper'


describe ZMQ::Socket do
  
  subject { ZMQ::Socket.new type }
  let(:type) { ZMQ::SUB }
  
  its(:ptr) { should be_a FFI::Pointer }
  its(:context) { should eq ZMQ::DefaultContext }
  its(:type) { should eq ZMQ::SUB }
  its(:type_sym) { should eq :SUB }
  
  it "can bind to an endpoint" do
    subject.bind 'ipc:///tmp/test'
  end
  
  it "will raise on a bad call to bind" do
    expect { subject.bind 'huh?://nope' }.to raise_error Errno::EPROTONOSUPPORT
  end
  
  it "can unbind from an endpoint" do
    subject.bind   'ipc:///tmp/test'
    subject.unbind 'ipc:///tmp/test'
  end
  
  it "will raise on a bad call to unbind" do
    expect { subject.unbind 'ipc:///tmp/test' }.to raise_error Errno::ENOENT
  end
  
  it "can connect to an endpoint" do
    subject.connect 'ipc:///tmp/test'
  end
  
  it "will raise on a bad call to connect" do
    expect { subject.connect 'huh?://?' }.to raise_error Errno::EPROTONOSUPPORT
  end
  
  it "can disconnect from an endpoint" do
    subject.connect    'ipc:///tmp/test'
    subject.disconnect 'ipc:///tmp/test'
  end
  
  it "will raise on a bad call to disconnect" do
    expect { subject.disconnect 'ipc:///tmp/test' }.to raise_error Errno::ENOENT
  end
  
  it "can get and set int socket options" do
    subject.get_opt(ZMQ::BACKLOG).should eq 100 # Default value
    subject.set_opt ZMQ::BACKLOG,           99
    subject.get_opt(ZMQ::BACKLOG).should eq 99
  end
  
  it "can get and set int64 socket options" do
    subject.get_opt(ZMQ::MAXMSGSIZE).should eq -1 # Default value
    subject.set_opt ZMQ::MAXMSGSIZE,           0x7FFFFFFFFFFFFFFF
    subject.get_opt(ZMQ::MAXMSGSIZE).should eq 0x7FFFFFFFFFFFFFFF
  end
  
  it "can get and set uint64 socket options" do
    subject.get_opt(ZMQ::AFFINITY).should eq 0 # Default value
    subject.set_opt ZMQ::AFFINITY,           0xFFFFFFFFFFFFFFFF
    subject.get_opt(ZMQ::AFFINITY).should eq 0xFFFFFFFFFFFFFFFF
  end
  
  it "can set string socket options" do
    subject.set_opt ZMQ::SUBSCRIBE, 'topic.name'
  end
  
  it "can get string socket options" do
    subject.bind 'ipc:///tmp/test'
    subject.get_opt(ZMQ::LAST_ENDPOINT).should eq 'ipc:///tmp/test'
  end
  
  it "will raise on a bad call to set_opt" do
    expect { subject.set_opt ZMQ::IDENTITY, "\x00 can't start with zero" }.to \
      raise_error Errno::EINVAL
  end
  
end
