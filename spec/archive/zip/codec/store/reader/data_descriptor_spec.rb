# encoding: UTF-8

require 'minitest/autorun'
require 'zlib'

require 'archive/zip/codec/store'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Store::Reader#data_descriptor' do
  it 'is an instance of Archive::Zip::DataDescriptor' do
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Reader.open(
        cd
      ) do |decompressor|
        decompressor.read(8192)
        decompressor.data_descriptor.must_be_instance_of(
          Archive::Zip::DataDescriptor
        )
        decompressor
      end
      closed_decompressor.data_descriptor.must_be_instance_of(
        Archive::Zip::DataDescriptor
      )
    end
  end

  it 'has a crc32 attribute containing the CRC32 checksum' do
    crc32 = Zlib.crc32(StoreSpecs.test_data)
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Reader.open(
        cd
      ) do |decompressor|
        decompressor.read(8192)
        decompressor.data_descriptor.crc32.must_equal crc32
        decompressor
      end
      closed_decompressor.data_descriptor.crc32.must_equal crc32
    end
  end

  it 'has a compressed_size attribute containing the size of the compressed data' do
    size = StoreSpecs.test_data.bytesize
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Reader.open(
        cd
      ) do |decompressor|
        decompressor.read(8192)
        decompressor.data_descriptor.compressed_size.must_equal size
        decompressor
      end
      closed_decompressor.data_descriptor.compressed_size.must_equal size
    end
  end

  it 'has an uncompressed_size attribute containing the size of the input data' do
    size = StoreSpecs.test_data.bytesize
    StoreSpecs.compressed_data do |cd|
      closed_decompressor = Archive::Zip::Codec::Store::Reader.open(
        cd
      ) do |decompressor|
        decompressor.read(8192)
        decompressor.data_descriptor.uncompressed_size.must_equal size
        decompressor
      end
      closed_decompressor.data_descriptor.uncompressed_size.must_equal size
    end
  end
end
