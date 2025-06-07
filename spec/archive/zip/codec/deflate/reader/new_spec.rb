# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Reader.new' do
  it 'returns a new instance' do
    DeflateSpecs.string_io do |sio|
      d = Archive::Zip::Codec::Deflate::Reader.new(sio)
      _(d).must_be_instance_of(Archive::Zip::Codec::Deflate::Reader)
      d.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    DeflateSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Deflate::Reader.new(sio)
      c.close
      _(sio.closed?).must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    DeflateSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Deflate::Reader.new(sio, autoclose: false)
      c.close
      _(sio.closed?).must_equal false
    end
  end

  it 'does not require window_bits to be set' do
    data = DeflateSpecs.test_data
    compressed_data = DeflateSpecs.string_io
    Archive::Zip::Codec::Deflate::Writer.open(
      compressed_data, autoclose: false
    ) do |zw|
      zw.write(data)
    end
    compressed_data.seek(0)

    zr = Archive::Zip::Codec::Deflate::Reader.new(compressed_data)
    _(zr.read(8192)).must_equal data
    zr.close
  end
end
