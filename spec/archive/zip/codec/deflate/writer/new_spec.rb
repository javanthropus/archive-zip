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
end
