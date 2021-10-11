# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZReader#compressed_size' do
  it 'returns the number of bytes of compressed data' do
    closed_zr = ZlibSpecs.compressed_data_raw do |compressed_data|
      Zlib::ZReader.open(compressed_data, window_bits: -15) do |zr|
        zr.read(8192)
        zr.compressed_size.must_equal 160
        zr
      end
    end
    closed_zr.compressed_size.must_equal 160
  end
end
