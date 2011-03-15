require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZReader#read" do
  it "calls the read method of the delegate" do
    delegate = mock('delegate')
    delegate.should_receive(:read).and_return(nil)
    Zlib::ZReader.open(delegate) do |zr|
      # Capture and ignore the Zlib::BufError which is generated due to mocking.
      begin
        zr.read
      rescue Zlib::BufError
      end
    end
  end

  it "decompresses compressed data" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        zr.read.should == ZlibSpecs.test_data
      end
    end
  end

  it "raises Zlib::DataError when reading invalid data" do
    Zlib::ZReader.open(BinaryStringIO.new('This is not compressed data')) do |zr|
      lambda { zr.read }.should raise_error(Zlib::DataError)
    end
  end

  it "raises Zlib::BufError when reading truncated data" do
    truncated_data = ZlibSpecs.compressed_data { |cd| cd.read(100) }
    Zlib::ZReader.open(BinaryStringIO.new(truncated_data)) do |zr|
      lambda { zr.read }.should raise_error(Zlib::BufError)
    end
  end

  it "raises Zlib::BufError when reading empty data" do
    Zlib::ZReader.open(BinaryStringIO.new()) do |zr|
      lambda { zr.read }.should raise_error(Zlib::BufError)
    end
  end
end
