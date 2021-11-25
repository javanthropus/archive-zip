# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/traditional_encryption'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::TraditionalEncryption::Reader#seek' do
  it 'can seek to the beginning of the stream when the delegate can do so' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        r.read(4)
        _(r.seek(0)).must_equal 0
      end
    end
  end

  it 'can report the current position of the stream' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        r.read(4)
        _(r.seek(0, IO::SEEK_CUR)).must_equal 4
      end
    end
  end

  it 'does not modify the stream if the delegate cannot seek' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      # Override #seek to behave as if it would block on the first call.
      class << ed
        alias :seek_orig :seek
        def seek(amount, whence = IO::SEEK_SET)
          @do_seek = defined?(@do_seek)

          return :wait_readable unless @do_seek

          seek_orig(amount, whence)
        end
      end

      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        r.read(4)
        _(r.seek(0, IO::SEEK_SET)).must_be_kind_of Symbol
        _(r.seek(0, IO::SEEK_CUR)).wont_equal 0
      end
    end
  end

  it 'raises Errno::ESPIPE when attempting to seek to the beginning of the stream when the delegate is not seekable' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      def ed.seek(offset, whence = IO::SEEK_SET)
        raise Errno::ESPIPE
      end

      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        _(lambda { r.seek(0) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking forward or backward from the current position of the stream' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        r.read(4)
        _(lambda { r.seek(1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
        _(lambda { r.seek(-1, IO::SEEK_CUR) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking a non-zero offset relative to the beginning of the stream' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        _(lambda { r.seek(-1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
        _(lambda { r.seek(1, IO::SEEK_SET) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::ESPIPE when seeking relative to the end of the stream' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        _(lambda { r.seek(0, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { r.seek(-1, IO::SEEK_END) }).must_raise Errno::ESPIPE
        _(lambda { r.seek(1, IO::SEEK_END) }).must_raise Errno::ESPIPE
      end
    end
  end

  it 'raises Errno::EINVAL when an invalid whence value is provided' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |r|
        _(lambda { r.seek(0, nil) }).must_raise Errno::EINVAL
        _(lambda { r.seek(0, 'invalid') }).must_raise Errno::EINVAL
      end
    end
  end
end
