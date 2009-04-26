require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt.new" do
  it "returns a new instance" do
    e = Archive::Zip::Codec::TraditionalEncryption::Encrypt.new(
      StringIO.new,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    e.class.should == Archive::Zip::Codec::TraditionalEncryption::Encrypt
    e.close
  end
end
