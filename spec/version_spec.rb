
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
  
end
