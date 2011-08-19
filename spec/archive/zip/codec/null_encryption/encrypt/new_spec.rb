# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt.new" do
  it "returns a new instance" do
    e = Archive::Zip::Codec::NullEncryption::Encrypt.new(BinaryStringIO.new)
    e.class.should == Archive::Zip::Codec::NullEncryption::Encrypt
    e.close
  end
end
