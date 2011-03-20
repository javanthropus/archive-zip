# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#tell" do
  it "returns the current position of the stream" do
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.tell.should == 0
      e.write('test1')
      e.tell.should == 5
      e.write('test2')
      e.tell.should == 10
      e.rewind
      e.tell.should == 0
    end
  end

  it "raises IOError on closed stream" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).once.and_return(nil)
    lambda do
      Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
        delegate,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) { |e| e }.tell
    end.should raise_error(IOError)
  end
end
