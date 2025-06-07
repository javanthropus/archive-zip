# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/writer'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer#compressed_size' do
  it 'returns the number of bytes of compressed data' do
    size = DeflateSpecs.compressed_data.bytesize
    DeflateSpecs.string_io do |sio|
      closed_zw = Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write(DeflateSpecs.test_data)
        zw.write('') # Causes a flush to the deflater
        _(zw.compressed_size).must_be :>=, 0
        zw
      end
      _(closed_zw.compressed_size).must_equal size
    end
  end
end
