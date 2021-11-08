# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/store'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Store::Writer#write' do
  it 'passes data through unmodified' do
    StoreSpecs.string_io do |sio|
      Archive::Zip::Codec::Store::Writer.open(sio, autoclose: false) do |c|
        c.write(StoreSpecs.test_data)
      end
      sio.seek(0)
      _(sio.read(8192)).must_equal(StoreSpecs.compressed_data)
    end
  end
end
