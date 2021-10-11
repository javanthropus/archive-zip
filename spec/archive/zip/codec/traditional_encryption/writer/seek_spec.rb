# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/traditional_encryption'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::TraditionalEncryption::Writer#seek' do
  it 'can seek to the beginning of the stream when the delegate can do so' do
    TraditionalEncryptionSpecs.string_io do |sio|
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |w|
        w.write('test')
        w.seek(0).must_equal 0
      end
    end
  end

  it 'can report the current position of the stream' do
    TraditionalEncryptionSpecs.string_io do |sio|
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |w|
        w.write('test')
        w.seek(0, IO::SEEK_CUR).must_equal 4
      end
    end
  end

  it 'raises Errno::ESPIPE when attempting to seek to the beginning of the stream when the delegate is not seekable' do
    TraditionalEncryptionSpecs.string_io do |sio|
      def sio.seek(offset, whence = IO::SEEK_SET)
        raise Errno::ESPIPE
      end

      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |w|
        lambda { w.seek(0) }.must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking forward or backward from the current position of the stream' do
    TraditionalEncryptionSpecs.string_io do |sio|
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |w|
        w.write('test')
        lambda { w.seek(1, IO::SEEK_CUR) }.must_raise Errno::ESPIPE
        lambda { w.seek(-1, IO::SEEK_CUR) }.must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking a non-zero offset relative to the beginning of the stream' do
    TraditionalEncryptionSpecs.string_io do |sio|
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |w|
        lambda { w.seek(-1, IO::SEEK_SET) }.must_raise Errno::ESPIPE
        lambda { w.seek(1, IO::SEEK_SET) }.must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking relative to the end of the stream' do
    TraditionalEncryptionSpecs.string_io do |sio|
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |w|
        lambda { w.seek(0, IO::SEEK_END) }.must_raise Errno::ESPIPE
        lambda { w.seek(-1, IO::SEEK_END) }.must_raise Errno::ESPIPE
        lambda { w.seek(1, IO::SEEK_END) }.must_raise Errno::ESPIPE
      end
    end
  end
end
