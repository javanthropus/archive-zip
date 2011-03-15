require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress#crc32" do
  it "computes the CRC32 checksum" do
    compressed_data = BinaryStringIO.new
    closed_compressor = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
      compressor.flush
      compressor.crc32.should == Zlib.crc32(DeflateSpecs.test_data)
      compressor
    end
    closed_compressor.crc32.should == Zlib.crc32(DeflateSpecs.test_data)
  end
end
