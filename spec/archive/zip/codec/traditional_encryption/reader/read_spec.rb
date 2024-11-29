# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/traditional_encryption'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::TraditionalEncryption::Reader#read' do
  it 'decrypts data read from the delegate' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        _(d.read(8192)).must_equal TraditionalEncryptionSpecs.test_data
      end
    end
  end

  it 'puts the decrypted bytes into given a buffer and returns number of bytes read' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        buffer = d.read(8192)
        _(buffer).must_equal TraditionalEncryptionSpecs.test_data
      end
    end
  end

  it 'decrypts data read from a delegate that only returns 1 byte at a time' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      # Override ed.read to read only 1 byte at a time.
      class << ed
        alias :read_orig :read
        def read(length, buffer: nil, buffer_offset: 0)
          read_orig(1, buffer: buffer, buffer_offset: buffer_offset)
        end
      end

      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        buffer = ''
        begin
          loop do
            result = d.read(8192)
            next if Symbol === result
            buffer << result
          end
        rescue EOFError
          # Finished reading.
        end
        _(buffer).must_equal TraditionalEncryptionSpecs.test_data
      end
    end
  end

  it 'decrypts data read from a delegate that returns :wait_readable' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      # Override ed.read to return :wait_readable every other time it's called.
      class << ed
        alias :read_orig :read
        def read(length, buffer: nil, buffer_offset: 0)
          @do_read = false unless defined?(:do_read)

          unless @do_read then
            @do_read = true
            return :wait_readable
          end

          @do_read = false
          read_orig(length, buffer: buffer, buffer_offset: buffer_offset)
        end
      end

      Archive::Zip::Codec::TraditionalEncryption::Reader.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        buffer = ''
        begin
          loop do
            result = d.read(8192)
            next if Symbol === result
            buffer << result
          end
        rescue EOFError
          # Finished reading.
        end
        _(buffer).must_equal TraditionalEncryptionSpecs.test_data
      end
    end
  end
end
