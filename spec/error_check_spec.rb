
require 'spec_helper'


describe 'ZMQ.error_check' do
  
  it "retrieves and raises the correct SystemCallError based on zmq_errno" do
    LibZMQ.should_receive(:zmq_errno) { 1 }
    expect { ZMQ.error_check }.to raise_error Errno::EPERM
  end
  
  it "raises SystemCallError with errno shown if errno is unrecognized" do
    LibZMQ.should_receive(:zmq_errno) { 156384763 }
    expect { ZMQ.error_check }.to raise_error SystemCallError, /156384763/
  end
  
end
