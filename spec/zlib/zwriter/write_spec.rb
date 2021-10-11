# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZWriter#write' do
  it 'compresses data' do
    data = ZlibSpecs.test_data
    ZlibSpecs.string_io do |sio|
      Zlib::ZWriter.open(sio, autoclose: false) do |zw|
        zw.write(data)
      end

      sio.seek(0)
      sio.read(8192).must_equal ZlibSpecs.compressed_data
    end
  end
end
