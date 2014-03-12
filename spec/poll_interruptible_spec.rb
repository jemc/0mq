
require 'spec_helper'

require 'poll_shared'


describe ZMQ::PollInterruptible do
  
  let(:poll_class) { ZMQ::PollInterruptible }
  
  it_behaves_like "a poll class"
  
end
