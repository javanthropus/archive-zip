# encoding: UTF-8

require 'minitest/autorun'
require 'zlib'

require 'archive/zip/codec/store'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Store::Writer#data_descriptor' do
  it 'is an instance of Archive::Zip::DataDescriptor' do
    test_data = StoreSpecs.test_data
    StoreSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Store::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.data_descriptor.must_be_instance_of(
          Archive::Zip::DataDescriptor
        )
        compressor
      end
      closed_compressor.data_descriptor.must_be_instance_of(
        Archive::Zip::DataDescriptor
      )
    end
  end

  it 'has a crc32 attribute containing the CRC32 checksum' do
    test_data = StoreSpecs.test_data
    crc32 = Zlib.crc32(test_data)
    StoreSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Store::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.data_descriptor.crc32.must_equal crc32
        compressor
      end
      closed_compressor.data_descriptor.crc32.must_equal crc32
    end
  end

  it 'has a compressed_size attribute containing the size of the compressed data' do
    test_data = StoreSpecs.test_data
    size = test_data.bytesize
    StoreSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Store::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.data_descriptor.compressed_size.must_equal size
        compressor
      end
      closed_compressor.data_descriptor.compressed_size.must_equal size
    end
  end

  it 'has an uncompressed_size attribute containing the size of the input data' do
    test_data = StoreSpecs.test_data
    size = test_data.bytesize
    StoreSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Store::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.data_descriptor.uncompressed_size.must_equal size
        compressor
      end
      closed_compressor.data_descriptor.uncompressed_size.must_equal size
    end
  end
end
