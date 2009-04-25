require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/deflate'
require 'stringio'

describe "Archive::Zip::Codec::Deflate::Decompress.new" do
  it "returns a new instance" do
    d = Archive::Zip::Codec::Deflate::Decompress.new(StringIO.new)
    d.class.should == Archive::Zip::Codec::Deflate::Decompress
    d.close
  end
end
