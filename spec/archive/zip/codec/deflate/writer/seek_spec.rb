# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/writer'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer#seek' do
  it 'can seek to the beginning of the stream when the delegate can do so' do
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write('test')
        _(zw.seek(0)).must_equal 0
      end
    end
  end

  it 'can seek report the current position of the stream' do
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write('test')
        _(zw.seek(0, IO::SEEK_CUR)).must_equal 4
      end
    end
  end

  it 'does not modify the stream if the delegate cannot seek' do
    DeflateSpecs.string_io do |sio|
      # Override #seek to behave as if it would block on the first call.
      class << sio
        alias :seek_orig :seek
        def seek(amount, whence = IO::SEEK_SET)
          @do_seek = defined?(@do_seek)

          return :wait_readable unless @do_seek

          seek_orig(amount, whence)
        end
      end

      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write('data')
        _(zw.seek(0, IO::SEEK_SET)).must_be_kind_of Symbol
        _(zw.seek(0, IO::SEEK_CUR)).wont_equal 0
      end
    end
  end

  it 'raises Errno::ESPIPE when attempting to seek to the beginning of the stream when the delegate is not seekable' do
    DeflateSpecs.string_io do |sio|
      def sio.seek(offset, whence = IO::SEEK_SET)
        raise Errno::ESPIPE
      end

      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(0) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking forward or backward from the current position of the stream' do
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(-1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking a non-zero offset relative to the beginning of the stream' do
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(-1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking relative to the end of the stream' do
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(0, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(1, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(-1, IO::SEEK_END) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::EINVAL when an invalid whence value is provided' do
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(sio) do |zw|
        _(lambda { zw.seek(0, nil) }).must_raise Errno::EINVAL
        _(lambda { zw.seek(0, 'invalid') }).must_raise Errno::EINVAL
      end
    end
  end
end
