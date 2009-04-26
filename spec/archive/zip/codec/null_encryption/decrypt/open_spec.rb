require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::NullEncryption::Decrypt.open" do
  it "returns a new instance when run without a block" do
    d = Archive::Zip::Codec::NullEncryption::Decrypt.open(StringIO.new)
    d.class.should == Archive::Zip::Codec::NullEncryption::Decrypt
    d.close
  end

  it "executes a block with a new instance as an argument" do
    Archive::Zip::Codec::NullEncryption::Decrypt.open(StringIO.new) do |decryptor|
      decryptor.class.should == Archive::Zip::Codec::NullEncryption::Decrypt
    end
  end

  it "closes the object after executing a block" do
    d = Archive::Zip::Codec::NullEncryption::Decrypt.open(StringIO.new) do |decryptor|
      decryptor
    end
    d.closed?.should.be_true
  end
end
