# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/reader'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Reader#seek' do
  it 'can seek to the beginning of the stream when the delegate can do so' do
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        zr.read(4)
        _(zr.seek(0)).must_equal 0
      end
    end
  end

  it 'can report the current position of the stream' do
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        zr.read(4)
        _(zr.seek(0, IO::SEEK_CUR)).must_equal 4
      end
    end
  end

  it 'raises Errno::ESPIPE when attempting to seek to the beginning of the stream when the delegate is not seekable' do
    DeflateSpecs.compressed_data do |cd|
      def cd.seek(offset, whence = IO::SEEK_SET)
        raise Errno::ESPIPE
      end

      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.seek(0) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking forward or backward from the current position of the stream' do
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        zr.read(4)
        _(lambda { zr.seek(1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
        _(lambda { zr.seek(-1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking a non-zero offset relative to the beginning of the stream' do
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.seek(-1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
        _(lambda { zr.seek(1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking relative to the end of the stream' do
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.seek(0, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { zr.seek(-1, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { zr.seek(1, IO::SEEK_END) }).must_raise Errno::ESPIPE
      end
    end
  end
end
