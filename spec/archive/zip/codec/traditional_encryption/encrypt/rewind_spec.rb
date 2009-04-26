require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    encrypted_data = StringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write('test')
      # Ensure repeatable test data is used for encryption header.
      srand(0)
      lambda { e.rewind }.should_not raise_error
      e.write(TraditionalEncryptionSpecs.test_data)
    end
    encrypted_data.string.should == TraditionalEncryptionSpecs.encrypted_data
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).once.and_return(nil)
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      lambda { e.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
