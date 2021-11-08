# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/traditional_encryption'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::TraditionalEncryption::Writer#write' do
  it 'writes encrypted data to the delegate' do
    test_data = TraditionalEncryptionSpecs.test_data
    TraditionalEncryptionSpecs.string_io do |sio|
      srand(0)
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |e|
        # Ensure repeatable test data is used for encryption header.
        e.write(test_data)

        sio.seek(0)
        _(sio.read(8192)).must_equal(TraditionalEncryptionSpecs.encrypted_data)
      end
    end
  end

  it 'writes encrypted data to a delegate that only performs partial writes' do
    test_data = TraditionalEncryptionSpecs.test_data
    TraditionalEncryptionSpecs.string_io do |sio|
      # Override sio.write to perform writes 1 byte at a time.
      class << sio
        alias :write_orig :write
        def write(buffer, length: buffer.bytesize)
          write_orig(buffer[0, 1])
        end
      end

      # Ensure repeatable test data is used for encryption header.
      srand(0)
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime,
        autoclose: false
      ) do |e|
        bytes_written = 0
        while bytes_written < test_data.bytesize
          result = e.write(test_data[bytes_written..-1])
          next if Symbol === result
          bytes_written += result
        end

        sio.seek(0)
        _(sio.read(8192)).must_equal(TraditionalEncryptionSpecs.encrypted_data)
      end
    end
  end

  it 'writes encrypted data to a delegate that returns :wait_writable' do
    test_data = TraditionalEncryptionSpecs.test_data
    TraditionalEncryptionSpecs.string_io do |sio|
      # Override sio.write to return :wait_writable every other time it's called.
      class << sio
        alias :write_orig :write
        def write(buffer, length: buffer.bytesize)
          @do_write = false unless defined?(@do_write)

          unless @do_write
            @do_write = true
            return :wait_writable
          end

          @do_write = false
          write_orig(buffer, length: length)
        end
      end

      # Ensure repeatable test data is used for encryption header.
      srand(0)
      Archive::Zip::Codec::TraditionalEncryption::Writer.open(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime,
        autoclose: false
      ) do |e|
        bytes_written = 0
        while bytes_written < test_data.bytesize
          result = e.write(test_data[bytes_written..-1])
          next if Symbol === result
          bytes_written += result
        end
      end

      sio.seek(0)
      _(sio.read(8192)).must_equal(TraditionalEncryptionSpecs.encrypted_data)
    end
  end
end
