require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::TraditionalEncryption::Decrypt.new(
      StringIO.new("\000" * 12),
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    )
    d.class.should == Archive::Zip::Codec::TraditionalEncryption::Decrypt
    d.close
  end
end
