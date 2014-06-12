
require 'spec_helper'

require 'poll_shared'


describe ZMQ::PollInterruptible do
  
  let(:poll_class) { ZMQ::PollInterruptible }
  
  it_behaves_like "a poll class"
  
  describe do
    let!(:never_sock) { ZMQ::Socket.new(ZMQ::PULL) } # A socket never used
    subject { poll_class.new never_sock }
    
    around { |test| Timeout.timeout(5) { test.run } }
    
    after { subject.close unless subject.dead? }
    
    it "can be interrupted" do
      subject
      interruptions = []
      
      3.times do
        thr = Thread.new { subject.run { |*args| interruptions << args } }
        subject.interrupt.should eq true
        thr.join
      end
      
      interruptions.count.should eq 3
      interruptions.each { |sock,evts| sock.should eq nil; evts.should eq nil }
    end
    
    it "can be interrupted with a block" do
      subject
      interruptions = []
      bools = {}
      
      threads = 3.times.map do |i|
        bools[i] = false
        thr = Thread.new {
          subject.run { |*args| interruptions << args; bools[i].should eq true }
        }
        subject.interrupt { bools[i] = true; i }.should eq i
        thr
      end
      threads.each &:join
      
      interruptions.count.should eq 3
      interruptions.each { |sock,evts| sock.should eq nil; evts.should eq nil }
    end
    
    it "can be killed" do
      subject
      subject.dead?.should eq false
      
      Thread.new {
        loop {
          break if subject.dead?
          subject.run { |sock,evts| sock.should eq nil; evts.should eq nil }
        }
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
