# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/store'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Store::Reader.new' do
  it 'returns a new instance' do
    StoreSpecs.string_io do |sio|
      d = Archive::Zip::Codec::Store::Reader.new(sio)
      _(d).must_be_instance_of(Archive::Zip::Codec::Store::Reader)
      d.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    StoreSpecs.string_io do |sio|
      d = Archive::Zip::Codec::Store::Reader.new(sio)
      d.close
      _(sio.closed?).must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    StoreSpecs.string_io do |sio|
      d = Archive::Zip::Codec::Store::Reader.new(sio, autoclose: false)
      d.close
      _(sio.closed?).must_equal false
    end
  end
end
