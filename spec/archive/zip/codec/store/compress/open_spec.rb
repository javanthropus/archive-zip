require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::Store::Compress.open" do
  it "returns a new instance when run without a block" do
    c = Archive::Zip::Codec::Store::Compress.open(StringIO.new)
    c.class.should == Archive::Zip::Codec::Store::Compress
    c.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::Store::Compress.open(StringIO.new) do |compressor|
      compressor.class.should == Archive::Zip::Codec::Store::Compress
    end
  end

  it "closes the object after executing a block" do
    c = Archive::Zip::Codec::Store::Compress.open(StringIO.new) do |compressor|
      compressor
    end
    c.closed?.should.be_true
  end
end
