
shared_examples "a poll class" do
  
  subject { poll_class.new pull }
  
  let!(:push) { ZMQ::Socket.new(ZMQ::PUSH).tap { |s| s.bind    'inproc://pt' } }
  let!(:pull) { ZMQ::Socket.new(ZMQ::PULL).tap { |s| s.connect 'inproc://pt' } }
  let(:pushX) { ZMQ::Socket.new(ZMQ::PUSH).tap { |s| s.connect 'inproc://XX' } }
  let(:pull2) { ZMQ::Socket.new(ZMQ::PULL).tap { |s| s.connect 'inproc://pt' } }
  
  after {
    push.close
    pull.close
    pushX.close
    pull2.close
  }
  
  around { |test| Timeout.timeout(1) { test.run } }
  
  context "initializer socket args:" do
    it "can accept a single socket with no event flags" do
      push.send_string 'test'
      
      poll_class.new(pull).tap { |p|
        value = {pull => ZMQ::POLLIN}
        p.run.should eq value
      }
    end
    
    it "can accept multiple sockets with no event flags" do
      pull2
      
      push.send_string 'test'
      push.send_string 'test'
      
      poll_class.new(pull, pull2).tap { |p|
        p.run.count.should eq 2
      }
    end
    
    it "can accept a single socket with an event flag" do
      poll_class.new(push => ZMQ::POLLOUT).tap { |p|
        value = {push => ZMQ::POLLOUT}
        p.run.should eq value
      }
    end
    
    it "can accept multiple sockets with event flags" do
      pushX
      
      poll_class.new(push => ZMQ::POLLOUT, pushX => ZMQ::POLLOUT)
        .tap { |p| p.run.count.should eq 2 }
    end
    
    it "can accept multiple sockets with and without event flags" do
      pull2
      
      push.send_string 'test'
      push.send_string 'test'
      
      poll_class.new(pull, pull2, push => ZMQ::POLLOUT)
        .tap { |p| p.run.count.should eq 3 }
    end
  end
  
  context "initializer options:" do
    context "timeout:" do
      it "blocks indefinitely on timeout = -1" do
        expect {
          Timeout.timeout(0.1) { poll_class.new(pull, timeout: -1).run }
        }.to raise_error Timeout::Error
      end
      
      it "returns immediately on timeout = 0" do
        expect {
          Timeout.timeout(0.1) { poll_class.new(pull, timeout: 0).run }
        }.not_to raise_error
      end
      
      it "returns after timeout expiration" do
        expect {
          Timeout.timeout(0.1) { poll_class.new(pull, timeout: 0.01).run }
        }.not_to raise_error
      end
      
      it "implementes run_nonblock" do
        expect {
          Timeout.timeout(0.1) { poll_class.new(pull).run_nonblock }
        }.not_to raise_error
      end
      
      it "implements poll_nonblock" do
        expect {
          Timeout.timeout(0.1) { poll_class.poll_nonblock pull }
        }.not_to raise_error
      end
    end
  end
  
  context "return values:" do
    it "returns a hash of sockets ready for IO" do
      pull2
      
      push.send_string 'test'
      push.send_string 'test'
      
      results = poll_class.new(pull, pull2, push => ZMQ::POLLOUT).run
      
      results.count.should eq 3
      results[pull].should eq ZMQ::POLLIN
      results[pull2].should eq ZMQ::POLLIN
      results[push].should eq ZMQ::POLLOUT
    end
    
    it "passes sockets ready for IO to a block" do
      pull2
      
      push.send_string 'test'
      push.send_string 'test'
      
      results = {}
      poll_class.new(pull, pull2, push => ZMQ::POLLOUT)
        .run do |socket, events|
          results[socket] = events
        end
      
      results.count.should eq 3
      results[pull].should eq ZMQ::POLLIN
      results[pull2].should eq ZMQ::POLLIN
      results[push].should eq ZMQ::POLLOUT
    end
  end
  
  context "class poll method:" do
    subject { poll_class }
    
    it { should respond_to :poll }
    it { should respond_to :poll_nonblock }
    
    it "polls a socket" do
      push.send_string 'test'
      
      subject.poll(pull).count.should eq 1
    end
  end
  
end
