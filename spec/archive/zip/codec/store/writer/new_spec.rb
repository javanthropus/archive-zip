# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/store'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Store::Writer.new' do
  it 'returns a new instance' do
    StoreSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Store::Writer.new(sio)
      c.must_be_instance_of(Archive::Zip::Codec::Store::Writer)
      c.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    StoreSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Store::Writer.new(sio)
      c.close
      sio.closed?.must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    StoreSpecs.string_io do |sio|
      c = Archive::Zip::Codec::Store::Writer.new(sio, autoclose: false)
      c.close
      sio.closed?.must_equal false
    end
  end
end
