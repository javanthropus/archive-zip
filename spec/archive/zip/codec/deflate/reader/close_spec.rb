# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/reader'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Reader.close' do
  it 'closes the stream' do
    DeflateSpecs.compressed_data do |cd|
      zr = Archive::Zip::Codec::Deflate::Reader.new(cd)
      zr.close
      _(zr.closed?).must_equal true
    end
  end
end
