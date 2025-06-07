# encoding: UTF-8

require 'minitest/autorun'
require 'securerandom'

require 'archive/zip/codec/deflate/writer'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer.close' do
  it 'closes the stream' do
    zw = Archive::Zip::Codec::Deflate::Writer.new(DeflateSpecs.string_io)
    zw.close
    _(zw.closed?).must_equal true
  end

  it 'can be called multiple times without error' do
    zw = Archive::Zip::Codec::Deflate::Writer.new(DeflateSpecs.string_io)
    zw.close
    zw.close
  end

  it 'does not close the stream if the delegate cannot close' do
    # This data ensures that there is data to flush from the internal buffer.
    test_data = SecureRandom.random_bytes(1_000_000)
    DeflateSpecs.string_io do |sio|
      # Override #write to behave as if it would block on every other call
      # starting with the first.
      class << sio
        alias :write_orig :write
        def write(buffer, length: buffer.bytesize)
          @do_write = defined?(@do_write) && ! @do_write

          return :wait_writable unless @do_write

          write_orig(buffer, length: length)
        end
      end

      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write(test_data)
        _(zw.close).must_be_kind_of Symbol
        _(zw.closed?).must_equal false
        _(zw.close).must_be_kind_of Symbol
        _(zw.closed?).must_equal false
        _(zw.close).must_be_nil
        _(zw.closed?).must_equal true
      end
    end
  end
end
