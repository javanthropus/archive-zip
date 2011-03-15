require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress#checksum" do
  it "computes the CRC32 checksum" do
    compressed_data = BinaryStringIO.new
    closed_compressor = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
      compressor.flush
      compressor.checksum.should == Zlib.crc32(DeflateSpecs.test_data)
      compressor
    end
    closed_compressor.checksum.should == Zlib.crc32(DeflateSpecs.test_data)
  end

  it "computes the CRC32 checksum even when the delegate performs partial writes" do
    compressed_data = BinaryStringIO.new
    # Override compressed_data.write to perform writes 1 byte at a time.
    class << compressed_data
      alias :write_orig :write
      def write(buffer)
        write_orig(buffer.slice(0, 1))
      end
    end

    closed_compressor = Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
      compressor.flush
      compressor.checksum.should == Zlib.crc32(DeflateSpecs.test_data)
      compressor
    end
    closed_compressor.checksum.should == Zlib.crc32(DeflateSpecs.test_data)
  end
end
