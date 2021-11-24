# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/deflate/reader'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Deflate::Reader#read' do
  it 'decompresses compressed data' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(zr.read(8192)).must_equal test_data
      end
    end
  end

  it 'decompresses compressed data progressively in chunks smaller than the inflation buffer size' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(zr.read(5)).must_equal test_data[0, 5]
        _(zr.read(10)).must_equal test_data[5, 10]
      end
    end
  end

  it 'puts data in a given buffer and returns the bytes read' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        data = ''
        bytes_read = zr.read(8192, buffer: data)
        _(data).must_equal test_data
        _(bytes_read).must_equal test_data.bytesize
      end
    end
  end

  it 'reads compressed data from a delegate that only performs partial reads' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.compressed_data do |cd|
      # Override #read to perform reads 1 byte at a time.
      class << cd
        alias :read_orig :read
        def read(length, buffer: nil)
          read_orig(1, buffer: buffer)
        end
      end

      data = ''
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        begin
          loop do
            result = zr.read(8192)
            next if Symbol === result
            data << result
          end
        rescue EOFError
        end
      end
      _(data).must_equal test_data
    end
  end

  it 'reads compressed data from a non-blocking delegate that is sometimes not ready to read' do
    test_data = DeflateSpecs.test_data
    DeflateSpecs.compressed_data do |cd|
      # Override #read to behave as if it is non-blocking and would block on
      # every other call starting with the first.
      class << cd
        alias :read_orig :read
        def read(length, buffer: nil)
          @do_read = defined?(@do_read) && ! @do_read

          return :wait_readable unless @do_read

          read_orig(length, buffer: buffer)
        end
      end

      data = ''
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        begin
          loop do
            result = zr.read(8192)
            next if Symbol === result
            data << result
          end
        rescue EOFError
        end
      end
      _(data).must_equal test_data
    end
  end

  it 'raises ArgumentError when length is less than 0' do
    DeflateSpecs.string_io('This is not compressed data') do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.read(-1) }).must_raise ArgumentError
      end
    end
  end

  it 'raises Zlib::DataError when reading invalid data' do
    DeflateSpecs.string_io('This is not compressed data') do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.read(8192) }).must_raise Zlib::DataError
      end
    end
  end

  it 'raises Zlib::BufError when reading truncated data' do
    truncated_data = DeflateSpecs.compressed_data { |cd| cd.read(100) }
    DeflateSpecs.string_io(truncated_data) do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        zr.read(8192)
        _(lambda { zr.read(8192) }).must_raise Zlib::BufError
      end
    end
  end

  it 'raises Zlib::BufError when reading empty data' do
    DeflateSpecs.string_io do |cd|
      Archive::Zip::Codec::Deflate::Reader.open(cd) do |zr|
        _(lambda { zr.read(8192) }).must_raise Zlib::BufError
      end
    end
  end
end
