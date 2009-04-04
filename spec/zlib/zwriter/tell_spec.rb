require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'stringio'

describe "Zlib::ZWriter#tell" do
  it "returns the current position of the stream" do
    sio = StringIO.new
    Zlib::ZWriter.open(sio) do |zw|
      zw.tell.should == 0
      zw.write('test1')
      zw.tell.should == 5
      zw.write('test2')
      zw.tell.should == 10
      zw.rewind
      zw.tell.should == 0
    end
  end

  it "raises IOError on closed stream" do
    delegate = mock('delegate')
    delegate.should_receive(:write).at_least(:once).and_return(1)
    lambda do
      Zlib::ZWriter.open(delegate) { |zw| zw }.tell
    end.should raise_error(IOError)
  end
end
