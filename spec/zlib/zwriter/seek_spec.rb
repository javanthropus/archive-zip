# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/zlib'

require_relative '../fixtures/classes'

describe 'Zlib::ZWriter#seek' do
  it 'can seek to the beginning of the stream when the delegate can do so' do
    ZlibSpecs.string_io do |sio|
      Zlib::ZWriter.open(sio) do |zw|
        zw.write('test')
        _(zw.seek(0)).must_equal 0
      end
    end
  end

  it 'can seek report the current position of the stream' do
    ZlibSpecs.string_io do |sio|
      Zlib::ZWriter.open(sio) do |zw|
        zw.write('test')
        _(zw.seek(0, IO::SEEK_CUR)).must_equal 4
      end
    end
  end

  it 'raises Errno::ESPIPE when attempting to seek to the beginning of the stream when the delegate is not seekable' do
    ZlibSpecs.string_io do |sio|
      def sio.seek(offset, whence = IO::SEEK_SET)
        raise Errno::ESPIPE
      end

      Zlib::ZWriter.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(0) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking forward or backward from the current position of the stream' do
    ZlibSpecs.string_io do |sio|
      Zlib::ZWriter.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(-1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking a non-zero offset relative to the beginning of the stream' do
    ZlibSpecs.string_io do |sio|
      Zlib::ZWriter.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(-1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking relative to the end of the stream' do
    ZlibSpecs.string_io do |sio|
      Zlib::ZWriter.open(sio) do |zw|
        zw.write('test')
        _(lambda { zw.seek(0, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(1, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { zw.seek(-1, IO::SEEK_END) }).must_raise Errno::ESPIPE
      end
    end
  end
end
