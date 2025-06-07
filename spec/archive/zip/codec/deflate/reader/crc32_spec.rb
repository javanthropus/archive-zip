# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Deflate::Reader#crc32' do
  it 'computes a CRC32 checksum' do
    crc32 = Zlib.crc32(DeflateSpecs.test_data)
    closed_reader = DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |reader|
        reader.read(8192)
        _(reader.crc32).must_equal crc32
        reader
      end
    end
    _(closed_reader.crc32).must_equal crc32
  end
end
