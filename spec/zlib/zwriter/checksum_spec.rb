require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#checksum" do
  it "computes the ADLER32 checksum of zlib formatted data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, 15) do |zw|
      zw.write(ZlibSpecs.test_data)
      zw.flush
      zw.checksum.should == Zlib.adler32(ZlibSpecs.test_data)
      zw
    end
    closed_zw.checksum.should == Zlib.adler32(ZlibSpecs.test_data)
  end

  it "computes the CRC32 checksum of gzip formatted data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, 31) do |zw|
      zw.write(ZlibSpecs.test_data)
      zw.flush
      zw.checksum.should == Zlib.crc32(ZlibSpecs.test_data)
      zw
    end
    closed_zw.checksum.should == Zlib.crc32(ZlibSpecs.test_data)
  end

  it "does not compute a checksum for raw zlib data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, -15) do |zw|
      zw.write(ZlibSpecs.test_data)
      zw.flush
      zw.checksum.should == 1
      zw
    end
    closed_zw.checksum.should == 1
  end
end
