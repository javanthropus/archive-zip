# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZReader.new' do
  it 'returns a new instance' do
    ZlibSpecs.compressed_data do |cd|
      zr = Zlib::ZReader.new(cd)
      zr.class.must_equal Zlib::ZReader
      zr.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    ZlibSpecs.compressed_data do |cd|
      zr = Zlib::ZReader.new(cd)
      zr.close
      cd.closed?.must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    ZlibSpecs.compressed_data do |cd|
      zr = Zlib::ZReader.new(cd, autoclose: false)
      zr.close
      cd.closed?.must_equal false
    end
  end

  it 'does not require window_bits to be set' do
    data = ZlibSpecs.test_data
    compressed_data = ZlibSpecs.string_io
    Zlib::ZWriter.open(compressed_data, autoclose: false) do |zw|
      zw.write(data)
    end
    compressed_data.seek(0)

    zr = Zlib::ZReader.new(compressed_data)
    zr.read(8192).must_equal data
    zr.close
  end

  it 'allows window_bits to be set' do
    data = ZlibSpecs.test_data
    compressed_data = ZlibSpecs.string_io
    window_bits = -Zlib::MAX_WBITS
    Zlib::ZWriter.open(
      compressed_data,
      autoclose: false,
      level: Zlib::DEFAULT_COMPRESSION,
      window_bits: window_bits
    ) do |zw|
      zw.write(data)
    end
    compressed_data.seek(0)

    zr = Zlib::ZReader.new(compressed_data, window_bits: window_bits)
    zr.read(8192).must_equal data
    zr.close
  end
end
