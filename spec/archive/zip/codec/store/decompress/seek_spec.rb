# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        d.read(4)
        lambda { d.seek(0) }.should_not raise_error
      end
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::Store::Decompress.open(delegate) do |d|
      lambda { d.seek(0) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        # Disable read buffering to avoid some seeking optimizations implemented
        # by IO::Like which allow seeking forward within the buffer.
        d.fill_size = 0

        d.read(4)
        lambda { d.seek(1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
        lambda { d.seek(-1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
      end
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        lambda { d.seek(-1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
        lambda { d.seek(1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
      end
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        lambda { d.seek(0, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
        lambda { d.seek(-1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
        lambda { d.seek(1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
      end
    end
  end
end
