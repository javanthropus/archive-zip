# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    sio = BinaryStringIO.new
    Zlib::ZWriter.open(sio) do |zw|
      zw.write('test')
      lambda { zw.rewind }.should_not raise_error
      zw.write(ZlibSpecs.test_data)
    end
    sio.string.should == ZlibSpecs.compressed_data
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:write).at_least(:once).and_return(1)
    Zlib::ZWriter.open(delegate) do |zw|
      lambda { zw.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
