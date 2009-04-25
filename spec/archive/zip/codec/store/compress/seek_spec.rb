require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::Store::Compress#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    compressed_data = StringIO.new
    Archive::Zip::Codec::Store::Compress.open(compressed_data) do |c|
      c.write('test')
      lambda { c.seek(0) }.should_not raise_error
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::Store::Compress.open(delegate) do |c|
      lambda { c.seek(0) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    compressed_data = StringIO.new
    Archive::Zip::Codec::Store::Compress.open(compressed_data) do |c|
      c.write('test')
      lambda { c.seek(1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
      lambda { c.seek(-1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    compressed_data = StringIO.new
    Archive::Zip::Codec::Store::Compress.open(compressed_data) do |c|
      lambda { c.seek(-1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
      lambda { c.seek(1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    compressed_data = StringIO.new
    Archive::Zip::Codec::Store::Compress.open(compressed_data) do |c|
      lambda { c.seek(0, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
      lambda { c.seek(-1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
      lambda { c.seek(1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
    end
  end
end
