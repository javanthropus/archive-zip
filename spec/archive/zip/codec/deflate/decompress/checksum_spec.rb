require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/deflate'

describe "Archive::Zip::Deflate::Decompress#checksum" do
  it "computes a CRC32 checksum" do
    closed_decompressor = DeflateSpecs.compressed_data_raw do |f|
      Archive::Zip::Codec::Deflate::Decompress.open(f) do |decompressor|
        decompressor.read
        decompressor.checksum.should == Zlib.crc32(DeflateSpecs.test_data)
        decompressor
      end
    end
    closed_decompressor.checksum.should == Zlib.crc32(DeflateSpecs.test_data)
  end
end
