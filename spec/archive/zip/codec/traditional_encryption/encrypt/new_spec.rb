require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt.new" do
  it "returns a new instance" do
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      BinaryStringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.class.should == Archive::Zip::Codec::TraditionalEncryption::Encrypt
    e.close
  end
end
