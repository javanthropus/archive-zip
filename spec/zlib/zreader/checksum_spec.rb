# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZReader#checksum' do
  it 'computes the ADLER32 checksum of zlib formatted data' do
    closed_zr = ZlibSpecs.compressed_data do |f|
      Zlib::ZReader.open(f, window_bits: 15) do |zr|
        zr.read(8192)
        zr.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
        zr
      end
    end
    closed_zr.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
  end

  it 'computes the CRC32 checksum of gzip formatted data' do
    crc32 = Zlib.crc32(ZlibSpecs.test_data)
    closed_zr = ZlibSpecs.compressed_data_gzip do |f|
      Zlib::ZReader.open(f, window_bits: 31) do |zr|
        zr.read(8192)
        zr.checksum.must_equal crc32
        zr
      end
    end
    closed_zr.checksum.must_equal crc32
  end

  it 'does not compute a checksum for raw zlib data' do
    closed_zr = ZlibSpecs.compressed_data_raw do |f|
      Zlib::ZReader.open(f, window_bits: -15) do |zr|
        zr.read(8192)
        zr.checksum.must_be_nil
        zr
      end
    end
    closed_zr.checksum.must_be_nil
  end
end
