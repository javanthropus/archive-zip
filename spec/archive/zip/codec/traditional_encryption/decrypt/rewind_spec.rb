# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        d.read(4)
        lambda { d.rewind }.should_not raise_error
        d.read.should == TraditionalEncryptionSpecs.test_data
      end
    end
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:read).with(an_instance_of(Fixnum)).at_least(:once).and_return { |n| "\000" * n }
    # Use the following instead for now.
    delegate.should_receive(:read).once.and_return("\000" * 12)
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |d|
      lambda { d.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
