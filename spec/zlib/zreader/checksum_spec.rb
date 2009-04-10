require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'

describe "Zlib::ZReader#checksum" do
  it "computes the ADLER32 checksum of zlib formatted data" do
    closed_zr = ZlibSpecs.compressed_data do |f|
      Zlib::ZReader.open(f, 15) do |zr|
        zr.read
        zr.checksum.should == Zlib.adler32(ZlibSpecs.test_data)
        zr
      end
    end
    closed_zr.checksum.should == Zlib.adler32(ZlibSpecs.test_data)
  end

  it "computes the CRC32 checksum of gzip formatted data" do
    closed_zr = ZlibSpecs.compressed_data_gzip do |f|
      Zlib::ZReader.open(f, 31) do |zr|
        zr.read
        zr.checksum.should == Zlib.crc32(ZlibSpecs.test_data)
        zr
      end
    end
    closed_zr.checksum.should == Zlib.crc32(ZlibSpecs.test_data)
  end

  it "does not compute a checksum for raw zlib data" do
    closed_zr = ZlibSpecs.compressed_data_raw do |f|
      Zlib::ZReader.open(f, -15) do |zr|
        zr.read
        zr.checksum.should == 1
        zr
      end
    end
    closed_zr.checksum.should == 1
  end
end
