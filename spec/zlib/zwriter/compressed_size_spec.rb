# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZWriter#compressed_size' do
  it 'returns the number of bytes of compressed data' do
    size = ZlibSpecs.compressed_data_minwin.bytesize
    ZlibSpecs.string_io do |sio|
      closed_zw = Zlib::ZWriter.open(sio, window_bits: -15) do |zw|
        zw.write(ZlibSpecs.test_data)
        zw.write('') # Causes a flush to the deflater
        zw.compressed_size.must_be :>=, 0
        zw
      end
      closed_zw.compressed_size.must_equal size
    end
  end
end
