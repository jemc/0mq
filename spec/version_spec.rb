
require 'spec_helper'

describe 'ZMQ::Version' do
  
  subject { ZMQ::Version }
  
  
  specify { ZMQ.version.should be ZMQ::Version }
  
  it "is a singleton" do
    expect { ZMQ::Version.new }.to raise_error NoMethodError
  end
  
  context "version accessors:" do
    its(:major) { should be_a Fixnum }
    its(:minor) { should be_a Fixnum }
    its(:patch) { should be_a Fixnum }
  end
  
  it "can return the version as a string" do
    str = subject.to_s
    match = str.match /(\d+)(\.)(\d+)(\.)(\d+)/
    
    match[1].should eq subject.major.to_s
    match[2].should eq '.'
    match[3].should eq subject.minor.to_s
    match[4].should eq '.'
    match[5].should eq subject.patch.to_s
  end
  
  context "version comparison:" do
    
    def make_version object, major = 0, minor = 0, patch = 0
      object = object.dup
      
      allow(object).to receive(:major) { major }
      allow(object).to receive(:minor) { minor }
      allow(object).to receive(:patch) { patch }
      
      object
    end
    
    
    subject { make_version ZMQ::Version, 4,0,3 }
    
    let(:higher_version) { make_version ZMQ::Version, 5,1,2 }
    let(:lower_version)  { make_version ZMQ::Version, 3,2,0 }
    let(:equal_version)  { make_version ZMQ::Version, 4,0,3 }
    
    context "spaceship operator:" do
      specify { (subject <=> "3").should eq 1 }
      specify { (subject <=> "4").should eq 0 }
      specify { (subject <=> "5").should eq -1 }
      
      specify { (subject <=> "3.2").should eq 1 }
      specify { (subject <=> "4.0").should eq 0 }
      specify { (subject <=> "5.1").should eq -1 }
      
      specify { (subject <=> "3.2.0").should eq 1 }
      specify { (subject <=> "4.0.3").should eq 0 }
      specify { (subject <=> "5.1.2").should eq -1 }
      
      specify { (subject <=> subject).should eq 0 }
      specify { (subject <=> equal_version).should eq 0 }
      specify { (subject <=> lower_version).should eq 1 }
      specify { (subject <=> higher_version).should eq -1 }
    end
    
    
    context "comparison operators:" do
      specify { (subject == "4").should eq     true }
      specify { (subject == "4.0").should eq   true }
      specify { (subject == "4.0.3").should eq true }
      
      specify { (subject == "3").should eq     false }
      specify { (subject == "3.2").should eq   false }
      specify { (subject == "3.2.0").should eq false }
      
      specify { (subject == "4.1").should eq   false }
      specify { (subject == "4.0.4").should eq false }
      
      
      specify { (subject != "4").should eq     false }
      specify { (subject != "4.0").should eq   false }
      specify { (subject != "4.0.3").should eq false }
      
      specify { (subject != "3").should eq     true }
      specify { (subject != "3.2").should eq   true }
      specify { (subject != "3.2.0").should eq true }
      
      specify { (subject != "4.1").should eq   true }
      specify { (subject != "4.0.4").should eq true }
      
      
      specify { (subject >  "3").should eq     true }
      specify { (subject >  "3.2").should eq   true }
      specify { (subject >  "3.2.0").should eq true }
      
      specify { (subject >  "4").should eq     false }
      specify { (subject >  "4.0").should eq   false }
      specify { (subject >  "4.0.3").should eq false }
      
      specify { (subject >  "5").should eq     false }
      specify { (subject >  "5.1").should eq   false }
      specify { (subject >  "5.1.2").should eq false }
      
      
      specify { (subject >= "3").should eq     true }
      specify { (subject >= "3.2").should eq   true }
      specify { (subject >= "3.2.0").should eq true }
      
      specify { (subject >= "4").should eq     true }
      specify { (subject >= "4.0").should eq   true }
      specify { (subject >= "4.0.3").should eq true }
      
      specify { (subject >= "5").should eq     false }
      specify { (subject >= "5.1").should eq   false }
      specify { (subject >= "5.1.2").should eq false }
      
      
      specify { (subject <  "3").should eq     false }
      specify { (subject <  "3.2").should eq   false }
      specify { (subject <  "3.2.0").should eq false }
      
      specify { (subject <  "4").should eq     false }
      specify { (subject <  "4.0").should eq   false }
      specify { (subject <  "4.0.3").should eq false }
      
      specify { (subject <  "5").should eq     true }
      specify { (subject <  "5.1").should eq   true }
      specify { (subject <  "5.1.2").should eq true }
      
      
      specify { (subject <= "3").should eq     false }
      specify { (subject <= "3.2").should eq   false }
      specify { (subject <= "3.2.0").should eq false }
      
      specify { (subject <= "4").should eq     true }
      specify { (subject <= "4.0").should eq   true }
      specify { (subject <= "4.0.3").should eq true }
      
      specify { (subject <= "5").should eq     true }
      specify { (subject <= "5.1").should eq   true }
      specify { (subject <= "5.1.2").should eq true }
    end
    
  end
  
end
