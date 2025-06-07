# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/writer'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer#uncompressed_size' do
  it 'returns the number of bytes of uncompressed data' do
    test_data = DeflateSpecs.test_data
    size = test_data.bytesize
    DeflateSpecs.string_io do |sio|
      closed_zw = Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write(test_data)
        _(zw.uncompressed_size).must_equal size
        zw
      end
      _(closed_zw.uncompressed_size).must_equal size
    end
  end
end
