# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#seek" do
  it "can seek to the beginning of the stream when the delegate responds to rewind" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write('test')
      lambda { e.seek(0) }.should_not raise_error
    end
  end

  it "raises Errno::EINVAL when attempting to seek to the beginning of the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      lambda { e.seek(0) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking forward or backward from the current position of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write('test')
      lambda { e.seek(1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(-1, IO::SEEK_CUR) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking a non-zero offset relative to the beginning of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      lambda { e.seek(-1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(1, IO::SEEK_SET) }.should raise_error(Errno::EINVAL)
    end
  end

  it "raises Errno::EINVAL when seeking relative to the end of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      lambda { e.seek(0, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(-1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
      lambda { e.seek(1, IO::SEEK_END) }.should raise_error(Errno::EINVAL)
    end
  end
end
