# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZWriter#uncompressed_size' do
  it 'returns the number of bytes of uncompressed data' do
    ZlibSpecs.string_io do |sio|
      closed_zw = Zlib::ZWriter.open(sio, window_bits: -15) do |zw|
        zw.write(ZlibSpecs.test_data)
        zw.uncompressed_size.must_equal 235
        zw
      end
      closed_zw.uncompressed_size.must_equal 235
    end
  end
end
