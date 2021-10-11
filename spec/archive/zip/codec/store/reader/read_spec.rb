# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/store'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Store::Reader#read' do
  it 'passes data through unmodified' do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Reader.open(cd) do |d|
        d.read(8192).must_equal(StoreSpecs.test_data)
      end
    end
  end
end
