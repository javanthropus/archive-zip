# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer.new' do
  it 'returns a new instance' do
    DeflateSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Deflate::Writer.new(sio)
      _(c).must_be_instance_of Archive::Zip::Codec::Deflate::Writer
      c.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    DeflateSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Deflate::Writer.new(sio)
      c.close
      _(sio.closed?).must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    DeflateSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Deflate::Writer.new(sio, autoclose: false)
      c.close
      _(sio.closed?).must_equal false
    end
  end

  it 'provides default settings for level, mem_level, and strategy' do
    data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      zw = Archive::Zip::Codec::Deflate::Writer.new(sio, autoclose: false)
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal DeflateSpecs.compressed_data
    end
  end

  it 'allows level to be set' do
    data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Deflate::Writer.new(
        sio, autoclose: false, level: Zlib::DEFAULT_COMPRESSION
      )
      c.write(data)
      c.close

      sio.seek(0)
      _(sio.read(8192)).must_equal DeflateSpecs.compressed_data
    end

    DeflateSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Deflate::Writer.new(
        sio, autoclose: false, level: Zlib::NO_COMPRESSION
      )
      c.write(data)
      c.close

      sio.seek(0)
      _(sio.read(8192)).must_equal DeflateSpecs.compressed_data_nocomp
    end
  end

  it 'allows mem_level to be set' do
    data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      zw = Archive::Zip::Codec::Deflate::Writer.new(
        sio, autoclose: false, mem_level: 1
      )
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal DeflateSpecs.compressed_data_minmem
    end
  end

  it 'allows strategy to be set' do
    data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      zw = Archive::Zip::Codec::Deflate::Writer.new(
        sio, autoclose: false, strategy: Zlib::HUFFMAN_ONLY
      )
      zw.write(data)
      zw.close

      sio.seek(0)
      _(sio.read(8192)).must_equal DeflateSpecs.compressed_data_huffman
    end
  end
end
