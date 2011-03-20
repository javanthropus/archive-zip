# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#close" do
  it "closes the stream" do
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(BinaryStringIO.new)
    e.close
    e.closed?.should be_true
  end

  it "closes the delegate stream by default" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(delegate)
    e.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(delegate)
    e.close(true)

    delegate = mock('delegate')
    delegate.should_not_receive(:close)
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(delegate)
    e.close(false)
  end
end
