# encoding: UTF-8

require 'minitest/autorun'

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
      sio.read(8192).must_equal(DeflateSpecs.compressed_data)
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
      sio.read(8192).must_equal(DeflateSpecs.compressed_data)
    end
  end

  it 'writes compressed data to a non-blocking delegate that is sometimes not ready to write' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.string_io do |sio|
      # Override #write to behave as if it is non-blocking and would block on
      # the first call.
      class << sio
        alias :write_orig :write
        def write(buffer, length: buffer.bytesize)
          @do_write = false unless defined?(@do_write)

          unless @do_write
            @do_write = true
            return :wait_writable
          end

          write_orig(buffer, length: length)
        end
      end

      Archive::Zip::Codec::Deflate::Writer.open(
        sio, autoclose: false
      ) do |compressor|
        bytes_written = 0
        while bytes_written < test_data.bytesize
          result = compressor.write(test_data[bytes_written..-1])
          if Symbol === result
            compressor.wait(IO::WRITABLE)
            next
          end
          bytes_written += result
        end
        compressor.wait(IO::WRITABLE) while Symbol === compressor.close
      end

      sio.seek(0)
      sio.read(8192).must_equal(DeflateSpecs.compressed_data)
    end
  end
end
