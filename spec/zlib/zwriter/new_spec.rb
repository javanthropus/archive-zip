# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZWriter.new' do
  it 'returns a new instance' do
    ZlibSpecs.string_io do |sio|
      zw = Zlib::ZWriter.new(sio)
      _(zw.class).must_equal Zlib::ZWriter
      zw.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    ZlibSpecs.string_io do |sio|
      zw = Zlib::ZWriter.new(sio)
      zw.close
      _(sio.closed?).must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    ZlibSpecs.string_io do |sio|
      zw = Zlib::ZWriter.new(sio, autoclose: false)
      zw.close
      _(sio.closed?).must_equal false
    end
  end

  it 'provides default settings for level, window_bits, mem_level, and strategy' do
    data = ZlibSpecs.test_data
    ZlibSpecs.string_io do |sio|
      zw = Zlib::ZWriter.new(sio, autoclose: false)
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal ZlibSpecs.compressed_data
    end
  end

  it 'allows level to be set' do
    data = ZlibSpecs.test_data
    ZlibSpecs.string_io do |sio|
      zw = Zlib::ZWriter.new(sio, autoclose: false, level: Zlib::NO_COMPRESSION)
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal ZlibSpecs.compressed_data_nocomp
    end
  end

  it 'allows window_bits to be set' do
    data = ZlibSpecs.test_data
    ZlibSpecs.string_io do |sio|
      zw = Zlib::ZWriter.new(sio, autoclose: false, window_bits: -15)
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal ZlibSpecs.compressed_data_minwin
    end
  end

  it 'allows mem_level to be set' do
    data = ZlibSpecs.test_data
    ZlibSpecs.string_io do |sio|
      zw = Zlib::ZWriter.new(sio, autoclose: false, mem_level: 1)
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal ZlibSpecs.compressed_data_minmem
    end
  end

  it 'allows strategy to be set' do
    data = ZlibSpecs.test_data
    ZlibSpecs.string_io do |sio|
      zw =
        Zlib::ZWriter.new(sio, autoclose: false, strategy: Zlib::HUFFMAN_ONLY)
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal ZlibSpecs.compressed_data_huffman
    end
  end
end
