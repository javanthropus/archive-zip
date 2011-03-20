# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/deflate'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Deflate::Compress#write" do
  it "calls the write method of the delegate" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).once.and_return(nil)
    Archive::Zip::Codec::Deflate::Compress.open(
      delegate, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
    end
  end

  it "writes compressed data to the delegate" do
    compressed_data = BinaryStringIO.new
    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
    end
    compressed_data.string.should == DeflateSpecs.compressed_data
  end

  it "writes compressed data to a delegate that only performs partial writes" do
    compressed_data = BinaryStringIO.new
    # Override compressed_data.write to perform writes 1 byte at a time.
    class << compressed_data
      alias :write_orig :write
      def write(buffer)
        write_orig(buffer.slice(0, 1))
      end
    end

    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      compressor.write(DeflateSpecs.test_data)
    end
    compressed_data.string.should == DeflateSpecs.compressed_data
  end

  it "writes compressed data to a delegate that raises Errno::EAGAIN" do
    compressed_data = BinaryStringIO.new
    # Override compressed_data.write to raise Errno::EAGAIN every other time it's
    # called.
    class << compressed_data
      alias :write_orig :write
      def write(buffer)
        if @error_raised then
          @error_raised = false
          write_orig(buffer)
        else
          @error_raised = true
          raise Errno::EAGAIN
        end
      end
    end

    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      begin
        compressor.write(DeflateSpecs.test_data)
      rescue Errno::EAGAIN
        retry
      end
    end
    compressed_data.string.should == DeflateSpecs.compressed_data
  end

  it "writes compressed data to a delegate that raises Errno::EINTR" do
    compressed_data = BinaryStringIO.new
    # Override compressed_data.write to raise Errno::EINTR every other time it's
    # called.
    class << compressed_data
      alias :write_orig :write
      def write(buffer)
        if @error_raised then
          @error_raised = false
          write_orig(buffer)
        else
          @error_raised = true
          raise Errno::EINTR
        end
      end
    end

    Archive::Zip::Codec::Deflate::Compress.open(
      compressed_data, Zlib::DEFAULT_COMPRESSION
    ) do |compressor|
      begin
        compressor.write(DeflateSpecs.test_data)
      rescue Errno::EINTR
        retry
      end
    end
    compressed_data.string.should == DeflateSpecs.compressed_data
  end
end
