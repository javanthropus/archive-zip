# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZWriter#checksum' do
  it 'computes the ADLER32 checksum of zlib formatted data' do
    ZlibSpecs.string_io do |sio|
      closed_zw = Zlib::ZWriter.open(sio, window_bits: 15) do |zw|
        zw.write(ZlibSpecs.test_data)
        zw.write('') # Causes a flush to the deflater
        zw.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
        zw
      end
      closed_zw.checksum.must_equal Zlib.adler32(ZlibSpecs.test_data)
    end
  end

  it 'computes the CRC32 checksum of gzip formatted data' do
    crc32 = Zlib.crc32(ZlibSpecs.test_data)
    ZlibSpecs.string_io do |sio|
      closed_zw = Zlib::ZWriter.open(sio, window_bits: 31) do |zw|
        zw.write(ZlibSpecs.test_data)
        zw.write('') # Causes a flush to the deflater
        zw.checksum.must_equal crc32
        zw
      end
      closed_zw.checksum.must_equal crc32
    end
  end

  it 'does not compute a checksum for raw zlib data' do
    ZlibSpecs.string_io do |sio|
      closed_zw = Zlib::ZWriter.open(sio, window_bits: -15) do |zw|
        zw.write(ZlibSpecs.test_data)
        zw.write('') # Causes a flush to the deflater
        zw.checksum.must_be_nil
        zw
      end
      closed_zw.checksum.must_be_nil
    end
  end
end
