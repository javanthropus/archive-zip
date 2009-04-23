require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/deflate'
require 'stringio'

describe "Archive::Zip::Codec::Deflate::Compress.open" do
  it "returns a new instance when run without a block" do
    c = Archive::Zip::Codec::Deflate::Compress.open(
      StringIO.new, Zlib::DEFAULT_COMPRESSION
    )
    c.class.should == Archive::Zip::Codec::Deflate::Compress
    c.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::Deflate::Compress.open(
      StringIO.new, Zlib::DEFAULT_COMPRESSION
    ) { |c| c.class.should == Archive::Zip::Codec::Deflate::Compress }
  end

  it "closes the object after executing a block" do
    Archive::Zip::Codec::Deflate::Compress.open(
      StringIO.new, Zlib::DEFAULT_COMPRESSION
    ) { |c| c }.closed?.should.be_true
  end

  it "allows level to be set" do
    data = DeflateSpecs.test_data
    compressed_data = StringIO.new
    c = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) { |c| c.write(data) }

    compressed_data.string.should == DeflateSpecs.compressed_data

    data = DeflateSpecs.test_data
    compressed_data = StringIO.new
    c = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::NO_COMPRESSION
    ) { |c| c.write(data) }

    compressed_data.string.should == DeflateSpecs.compressed_data_nocomp
  end
end
