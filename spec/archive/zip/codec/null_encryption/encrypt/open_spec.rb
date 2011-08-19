# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt.open" do
  it "returns a new instance when run without a block" do
    e = Archive::Zip::Codec::NullEncryption::Encrypt.open(BinaryStringIO.new)
    e.class.should == Archive::Zip::Codec::NullEncryption::Encrypt
    e.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::NullEncryption::Encrypt.open(BinaryStringIO.new) do |encryptor|
      encryptor.class.should == Archive::Zip::Codec::NullEncryption::Encrypt
    end
  end

  it "closes the object after executing a block" do
    e = Archive::Zip::Codec::NullEncryption::Encrypt.open(BinaryStringIO.new) do |encryptor|
      encryptor
    end
    e.closed?.should.be_true
  end
end
