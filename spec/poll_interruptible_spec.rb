
require 'spec_helper'

require 'poll_shared'


describe ZMQ::PollInterruptible do
  
  let(:poll_class) { ZMQ::PollInterruptible }
  
  it_behaves_like "a poll class"
  
  describe do
    let!(:never_sock) { ZMQ::Socket.new(ZMQ::PULL) } # A socket never used
    subject { poll_class.new never_sock }
    
    around { |test| Timeout.timeout(1) {test.run} } # Timeout after 1 second
    
    after { subject.close unless subject.dead? }
    
    it "can be interrupted" do
      subject
      interruptions = []
      run_proc = ->(*args){ interruptions << args }
      
      3.times do
        Thread.new { subject.run &run_proc }
              .tap { subject.interrupt.should eq true }
              .join
      end
      
      interruptions.count.should eq 3
      interruptions.each { |sock,evts| sock.should eq nil; evts.should eq nil }
    end
    
    it "can be killed" do
      subject
      subject.dead?.should eq false
      
      Thread.new {
        subject.run { |sock,evts| sock.should eq nil; evts.should eq nil }
      }.tap { subject.kill.should eq true }.join
      
      # Poll is now dead
      subject.dead?.should eq true
      expect { subject.run }.to raise_error RuntimeError
      subject.kill.should eq nil # return nil if already dead
      subject.close.should eq nil # return nil if already dead
    end
    
    it "can be closed" do
      subject
      subject.dead?.should eq false
      
      Thread.new { subject.run }.tap { subject.interrupt }.join
      
      subject.close.should eq true
      
      # Poll is now dead
      subject.dead?.should eq true
      expect { subject.run }.to raise_error RuntimeError
      subject.kill.should eq nil # return nil if already dead
      subject.close.should eq nil # return nil if already dead
    end
    
    it "can be instantiated and used with no sockets given" do
      subject = poll_class.new()
      
      Thread.new { subject.run }.tap { subject.interrupt.should eq true }.join
      Thread.new { subject.run }.tap { subject.interrupt.should eq true }.join
      Thread.new { subject.run }.tap { subject.kill.should eq true }.join
      
      # Poll is now dead
      subject.dead?.should eq true
      expect { subject.run }.to raise_error RuntimeError
      subject.kill.should eq nil # return nil if already dead
      subject.close.should eq nil # return nil if already dead
    end
  end
  
end
