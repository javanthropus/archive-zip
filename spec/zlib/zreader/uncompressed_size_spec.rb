# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZReader#uncompressed_size' do
  it 'returns the number of bytes of uncompressed data' do
    closed_zr = ZlibSpecs.compressed_data_raw do |compressed_data|
      Zlib::ZReader.open(compressed_data, window_bits: -15) do |zr|
        zr.read(8192)
        _(zr.uncompressed_size).must_equal 235
        zr
      end
    end
    _(closed_zr.uncompressed_size).must_equal 235
  end
end
