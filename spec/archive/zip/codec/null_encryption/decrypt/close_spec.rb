# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Decrypt#close" do
  it "closes the stream" do
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(BinaryStringIO.new)
    d.close
    d.closed?.should be_true
  end

  it "closes the delegate stream by default" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(delegate)
    d.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(delegate)
    d.close(true)

    delegate = mock('delegate')
    delegate.should_not_receive(:close)
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(delegate)
    d.close(false)
  end
end
