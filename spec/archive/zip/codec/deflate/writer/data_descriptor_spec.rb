# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer#data_descriptor' do
  it 'is an instance of Archive::Zip::DataDescriptor' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Deflate::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.write('') # Causes a flush to the deflater
        compressor.data_descriptor.class.must_equal Archive::Zip::DataDescriptor
        compressor
      end
      closed_compressor.data_descriptor.class.must_equal(
        Archive::Zip::DataDescriptor
      )
    end
  end

  it 'has a crc32 attribute containing the CRC32 checksum' do
    test_data = DeflateSpecs.test_data
    crc32 = Zlib.crc32(test_data)
    DeflateSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Deflate::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.write('') # Causes a flush to the deflater
        compressor.data_descriptor.crc32.must_equal crc32
        compressor
      end
      closed_compressor.data_descriptor.crc32.must_equal crc32
    end
  end

  it 'has a compressed_size attribute containing the size of the compressed data' do
    test_data = DeflateSpecs.test_data
    size = DeflateSpecs.compressed_data.bytesize
    DeflateSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Deflate::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.write('') # Causes a flush to the deflater
        compressor.data_descriptor.compressed_size.must_be :>=, 0
        compressor
      end
      closed_compressor.data_descriptor.compressed_size.must_equal size
    end
  end

  it 'has an uncompressed_size attribute containing the size of the input data' do
    test_data = DeflateSpecs.test_data
    size = test_data.bytesize
    DeflateSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Deflate::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.write('') # Causes a flush to the deflater
        compressor.data_descriptor.uncompressed_size.must_equal size
        compressor
      end
      closed_compressor.data_descriptor.uncompressed_size.must_equal size
    end
  end
end
