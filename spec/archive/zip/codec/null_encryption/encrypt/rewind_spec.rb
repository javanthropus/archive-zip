# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(encrypted_data) do |e|
      e.write('test')
      lambda { e.rewind }.should_not raise_error
      e.write(NullEncryptionSpecs.test_data)
    end
    encrypted_data.string.should == NullEncryptionSpecs.encrypted_data
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:close).once.and_return(nil)
    Archive::Zip::Codec::NullEncryption::Encrypt.open(delegate) do |e|
      lambda { e.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
