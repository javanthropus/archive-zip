# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer#crc32' do
  it 'computes the CRC32 checksum' do
    test_data = DeflateSpecs.test_data
    crc32 = Zlib.crc32(test_data)
    DeflateSpecs.string_io do |sio|
      closed_compressor = Archive::Zip::Codec::Deflate::Writer.open(
        sio
      ) do |compressor|
        compressor.write(test_data)
        compressor.write('') # Causes a flush to the deflater
        _(compressor.crc32).must_equal crc32
        compressor
      end
      _(closed_compressor.crc32).must_equal crc32
    end
  end
end
