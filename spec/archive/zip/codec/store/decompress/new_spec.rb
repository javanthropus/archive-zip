require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::Store::Decompress.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::Store::Decompress.new(StringIO.new)
    d.class.should == Archive::Zip::Codec::Store::Decompress
    d.close
  end
end
