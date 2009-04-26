require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'
require 'stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    encrypted_data = StringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      e.write('test')
      lambda { e.seek(0) }.should_not raise_error
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::NullEncryption::Encrypt.open(delegate) do |e|
      lambda { e.seek(0) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    encrypted_data = StringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      e.write('test')
      lambda { e.seek(1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(-1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    encrypted_data = StringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      lambda { e.seek(-1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    encrypted_data = StringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      lambda { e.seek(0, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(-1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
    end
  end
end
