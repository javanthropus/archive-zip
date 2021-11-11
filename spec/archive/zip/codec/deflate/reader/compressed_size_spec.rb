# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/reader'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Reader#compressed_size' do
  it 'returns the number of bytes of compressed data' do
    size = DeflateSpecs.compressed_data.bytesize
    closed_zr = DeflateSpecs.compressed_data do |compressed_data|
      Archive::Zip::Codec::Deflate::Reader.open(compressed_data) do |zr|
        zr.read(8192)
        _(zr.compressed_size).must_equal size
        zr
      end
    end
    _(closed_zr.compressed_size).must_equal size
  end
end
