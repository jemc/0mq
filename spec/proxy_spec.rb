
require 'spec_helper'


describe ZMQ::Proxy do
  
  let(:client)  { ZMQ::Socket.new(ZMQ::PUSH).tap{|s| s.connect 'ipc:///tmp/f'} }
  let(:frontend){ ZMQ::Socket.new(ZMQ::PULL).tap{|s| s.bind    'ipc:///tmp/f'} }
  let(:backend) { ZMQ::Socket.new(ZMQ::PUSH).tap{|s| s.bind    'ipc:///tmp/b'} }
  let(:service) { ZMQ::Socket.new(ZMQ::PULL).tap{|s| s.connect 'ipc:///tmp/b'} }
  
  subject { ZMQ::Proxy.new frontend, backend }
  
  around { |test| Timeout.timeout(1) {test.run} } # Timeout after 1 second
  
  
  it "forwards messages through the frontend to the backend" do
    thr = Thread.new { subject.run }
    client.send_array            ['some', 'workload', 'data']
    service.recv_array.should eq ['some', 'workload', 'data']
    thr.kill
  end
  
  it "can be instantiated and started with #proxy" do
    thr = Thread.new { ZMQ::Proxy.proxy frontend, backend }
    client.send_array            ['some', 'workload', 'data']
    service.recv_array.should eq ['some', 'workload', 'data']
    thr.kill
  end
  
end
