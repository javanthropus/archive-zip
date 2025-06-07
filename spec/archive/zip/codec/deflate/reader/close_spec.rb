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

  it 'can be called multiple times without error' do
    DeflateSpecs.compressed_data do |cd|
      zr = Archive::Zip::Codec::Deflate::Reader.new(cd)
      zr.close
      zr.close
    end
  end

  it 'does not close the stream if the delegate cannot close' do
    DeflateSpecs.compressed_data do |cd|
      # Override #close to behave as if it is non-blocking and would block on
      # the first call.
      class << cd
        alias :close_orig :close
        def close
          @do_close = defined?(@do_close)

          return :wait_readable unless @do_close

          close_orig
        end
      end

      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(zr.close).must_be_kind_of Symbol
        _(zr.closed?).must_equal false
        _(zr.close).must_be_nil
        _(zr.closed?).must_equal true
      end
    end
  end
end
