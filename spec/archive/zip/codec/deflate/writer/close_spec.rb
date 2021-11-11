# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/writer'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer.close' do
  it 'closes the stream' do
    zw = Archive::Zip::Codec::Deflate::Writer.new(DeflateSpecs.string_io)
    zw.close
    _(zw.closed?).must_equal true
  end
end
