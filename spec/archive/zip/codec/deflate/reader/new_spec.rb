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
end
