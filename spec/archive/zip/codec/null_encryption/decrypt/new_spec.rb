require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::NullEncryption::Decrypt.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::NullEncryption::Decrypt.new(StringIO.new)
    d.class.should == Archive::Zip::Codec::NullEncryption::Decrypt
    d.close
  end
end
