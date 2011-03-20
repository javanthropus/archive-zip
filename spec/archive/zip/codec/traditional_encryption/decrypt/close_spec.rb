# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt#close" do
  it "closes the stream" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      BinaryStringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close
    d.closed?.should be_true
  end

  it "closes the delegate stream by default" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:read).with(an_instance_of(Fixnum)).at_least(:once).and_return { |n| "\000" * n }
    # Use the following instead for now.
    delegate.should_receive(:read).once.and_return("\000" * 12)
    delegate.should_receive(:close).and_return(nil)
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:read).with(an_instance_of(Fixnum)).at_least(:once).and_return { |n| "\000" * n }
    # Use the following instead for now.
    delegate.should_receive(:read).once.and_return("\000" * 12)
    delegate.should_receive(:close).and_return(nil)
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close(true)

    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:read).with(an_instance_of(Fixnum)).at_least(:once).and_return { |n| "\000" * n }
    # Use the following instead for now.
    delegate.should_receive(:read).once.and_return("\000" * 12)
    delegate.should_not_receive(:close)
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.close(false)
  end
end
