require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt.open" do
  it "returns a new instance when run without a block" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      StringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.class.should == Archive::Zip::Codec::TraditionalEncryption::Decrypt
    d.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      StringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |decryptor|
      decryptor.class.should == Archive::Zip::Codec::TraditionalEncryption::Decrypt
    end
  end

  it "closes the object after executing a block" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      StringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |decryptor|
      decryptor
    end
    d.closed?.should.be_true
  end
end
