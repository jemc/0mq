
require 'spec_helper'


describe 'ZMQ.error_check' do
  
  it "retrieves and raises the correct SystemCallError based on zmq_errno" do
    LibZMQ.should_receive(:zmq_errno) { 1 }
    expect { ZMQ.error_check }.to raise_error Errno::EPERM
  end
  
  it "raises the correct SystemCallError for ZMQ-specific codes" do
    LibZMQ.should_receive(:zmq_errno) { ZMQ::EFSM }
    expect { ZMQ.error_check }.to raise_error Errno::EFSM, /wrong state/
    
    LibZMQ.should_receive(:zmq_errno) { ZMQ::ENOCOMPATPROTO }
    expect { ZMQ.error_check }.to raise_error Errno::ENOCOMPATPROTO, /protocol/
    
    LibZMQ.should_receive(:zmq_errno) { ZMQ::ETERM }
    expect { ZMQ.error_check }.to raise_error Errno::ETERM, /terminated/
    
    LibZMQ.should_receive(:zmq_errno) { ZMQ::EMTHREAD }
    expect { ZMQ.error_check }.to raise_error Errno::EMTHREAD, /I\/O thread/
  end
  
end
