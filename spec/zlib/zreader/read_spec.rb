# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZReader#read' do
  it 'decompresses compressed data' do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        zr.read(8192).must_equal ZlibSpecs.test_data
      end
    end
  end

  it 'raises Zlib::DataError when reading invalid data' do
    ZlibSpecs.string_io('This is not compressed data') do |cd|
      Zlib::ZReader.open(cd) do |zr|
        lambda { zr.read(8192) }.must_raise Zlib::DataError
      end
    end
  end

  it 'raises Zlib::BufError when reading truncated data' do
    truncated_data = ZlibSpecs.compressed_data { |cd| cd.read(100) }
    ZlibSpecs.string_io(truncated_data) do |cd|
      Zlib::ZReader.open(cd) do |zr|
        zr.read(8192)
        lambda { zr.read(8192) }.must_raise Zlib::BufError
      end
    end
  end

  it 'raises Zlib::BufError when reading empty data' do
    ZlibSpecs.string_io do |cd|
      Zlib::ZReader.open(cd) do |zr|
        lambda { zr.read(8192) }.must_raise Zlib::BufError
      end
    end
  end
end
