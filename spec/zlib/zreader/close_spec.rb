# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZReader.close' do
  it 'closes the stream' do
    ZlibSpecs.compressed_data do |cd|
      zr = Zlib::ZReader.new(cd)
      zr.close
      zr.closed?.must_equal true
    end
  end
end
