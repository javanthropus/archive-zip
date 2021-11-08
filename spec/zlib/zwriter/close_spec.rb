# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZWriter.close' do
  it 'closes the stream' do
    zw = Zlib::ZWriter.new(ZlibSpecs.string_io)
    zw.close
    _(zw.closed?).must_equal true
  end
end
