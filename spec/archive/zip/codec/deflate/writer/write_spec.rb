# encoding: UTF-8

require 'minitest/autorun'
require 'securerandom'

require 'archive/zip/codec/deflate'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Writer#write' do
  it 'writes compressed data to the delegate' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(
        sio, autoclose: false
      ) do |compressor|
        bytes_written = 0
        while bytes_written < test_data.bytesize
          result = compressor.write(test_data[bytes_written..-1])
          bytes_written += result
        end
      end
      sio.seek(0)
      _(sio.read(8192)).must_equal(DeflateSpecs.compressed_data)
    end
  end

  it 'writes partial data to the delegate when given an explicit length argument' do
    test_data = DeflateSpecs.test_data + 'extra'
    max_size = test_data.bytesize - 5
    DeflateSpecs.string_io do |sio|
      Archive::Zip::Codec::Deflate::Writer.open(
        sio, autoclose: false
      ) do |compressor|
        bytes_written = 0
        while bytes_written < max_size
          result = compressor.write(
            test_data[bytes_written..-1], length: max_size - bytes_written
          )
          bytes_written += result
        end
      end
      sio.seek(0)
      _(sio.read(8192)).must_equal(DeflateSpecs.compressed_data)
    end
  end

  it 'writes compressed data to a delegate that only performs partial writes' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      # Override #write to perform writes 1 byte at a time.
      class << sio
        alias :write_orig :write
        def write(buffer, length: buffer.bytesize)
          write_orig(buffer[0, 1])
        end
      end

      Archive::Zip::Codec::Deflate::Writer.open(
        sio, autoclose: false
      ) do |compressor|
        bytes_written = 0
        while bytes_written < test_data.bytesize
          result = compressor.write(test_data[bytes_written..-1])
          bytes_written += result
        end
      end

      sio.seek(0)
      _(sio.read(8192)).must_equal(DeflateSpecs.compressed_data)
    end
  end

  it 'writes compressed data to a non-blocking delegate that is sometimes not ready to write' do
    # This data ensures that there is data to flush from the internal buffer.
    test_data = SecureRandom.random_bytes(1_000_000)
    DeflateSpecs.string_io do |sio|
      # Override #write to behave as if would block on every other call starting
      # with the first.
      class << sio
        alias :write_orig :write
        def write(buffer, length: buffer.bytesize)
          @do_write = defined?(@do_write) && ! @do_write

          return :wait_writable unless @do_write

          write_orig(buffer, length: length)
        end
      end

      Archive::Zip::Codec::Deflate::Writer.open(
        sio, autoclose: false
      ) do |compressor|
        bytes_written = 0
        while bytes_written < test_data.bytesize
          result = compressor.write(test_data[bytes_written..-1], length: 100)
          if Symbol === result
            compressor.wait(IO::WRITABLE)
            next
          end
          bytes_written += result
        end
        compressor.wait(IO::WRITABLE) while Symbol === compressor.close
      end

      sio.seek(0)
      Archive::Zip::Codec::Deflate::Reader.open(
        sio, autoclose: false
      ) do |decompressor|
        data = ''
        begin
          loop do
            data << decompressor.read(8192)
          end
        rescue EOFError
        end
        _(data).must_equal test_data
      end
    end
  end
end
