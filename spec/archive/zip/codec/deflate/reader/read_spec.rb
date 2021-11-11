# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/reader'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Reader#read' do
  it 'decompresses compressed data' do
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(zr.read(8192)).must_equal DeflateSpecs.test_data
      end
    end
  end

  it 'raises Zlib::DataError when reading invalid data' do
    DeflateSpecs.string_io('This is not compressed data') do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.read(8192) }).must_raise Zlib::DataError
      end
    end
  end

  it 'raises Zlib::BufError when reading truncated data' do
    truncated_data = DeflateSpecs.compressed_data { |cd| cd.read(100) }
    DeflateSpecs.string_io(truncated_data) do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        zr.read(8192)
        _(lambda { zr.read(8192) }).must_raise Zlib::BufError
      end
    end
  end

  it 'raises Zlib::BufError when reading empty data' do
    DeflateSpecs.string_io do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.read(8192) }).must_raise Zlib::BufError
      end
    end
  end
end
