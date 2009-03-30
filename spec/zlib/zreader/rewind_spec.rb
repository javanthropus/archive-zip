require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'

describe "Zlib::ZReader#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    ZlibSpecs.compressed_file do |cf|
      Zlib::ZReader.open(cf) do |zr|
        zr.read(4)
        lambda { zr.rewind }.should_not raise_error
        zr.read.should == ZlibSpecs.test_data
      end
    end
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    Zlib::ZReader.open(Object.new) do |zr|
      lambda { zr.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
