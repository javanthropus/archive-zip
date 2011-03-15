require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Decrypt.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(BinaryStringIO.new)
    d.class.should == Archive::Zip::Codec::NullEncryption::Decrypt
    d.close
  end
end
