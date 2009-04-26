require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#close" do
  it "closes the stream" do
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      StringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close
    e.closed?.should be_true
  end

  it "closes the delegate stream by default" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).and_return(nil)
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).and_return(nil)
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close(true)

    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_not_receive(:close)
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.close(false)
  end
end
