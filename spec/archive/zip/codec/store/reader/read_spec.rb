# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/store'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::Store::Reader#read' do
  it 'passes data through unmodified' do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Reader.open(cd) do |d|
        _(d.read(8192)).must_equal(StoreSpecs.test_data)
      end
    end
  end

  it 'puts data in a given buffer and returns the bytes read' do
    test_data = StoreSpecs.test_data
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Reader.open(cd) do |d|
        data = ''
        bytes_read = d.read(8192, buffer: data)
        _(data).must_equal test_data
        _(bytes_read).must_equal test_data.bytesize
      end
    end
  end

  it 'reads data from a delegate that only performs partial reads' do
    test_data = StoreSpecs.test_data
    StoreSpecs.compressed_data do |cd|
      # Override #read to perform reads 1 byte at a time.
      class << cd
        alias :read_orig :read
        def read(length, buffer: nil)
          read_orig(1, buffer: buffer)
        end
      end

      data = ''
      Archive::Zip::Codec::Store::Reader.open(cd) do |d|
        begin
          loop do
            result = d.read(8192)
            next if Symbol === result
            data << result
          end
        rescue EOFError
        end
      end
      _(data).must_equal test_data
    end
  end

  it 'reads data from a non-blocking delegate that is sometimes not ready to read' do
    test_data = StoreSpecs.test_data
    StoreSpecs.compressed_data do |cd|
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
      Archive::Zip::Codec::Store::Reader.open(cd) do |d|
        begin
          loop do
            result = d.read(8192)
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
    StoreSpecs.string_io('This is not compressed data') do |cd|
      Archive::Zip::Codec::Store::Reader.open(cd) do |d|
        _(lambda { d.read(-1) }).must_raise ArgumentError
      end
    end
  end
end
