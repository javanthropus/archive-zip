require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'

describe "Archive::Zip::Codec::NullEncryption::Decrypt#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    NullEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::NullEncryption::Decrypt.open(ed) do |d|
        d.read(4)
        lambda { d.rewind }.should_not raise_error
        d.read.should == NullEncryptionSpecs.test_data
      end
    end
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::NullEncryption::Decrypt.open(delegate) do |d|
      lambda { d.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
