# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress.new" do
  it "returns a new instance" do
    c = Archive::Zip::Codec::Store::Compress.new(BinaryStringIO.new)
    c.class.should == Archive::Zip::Codec::Store::Compress
    c.close
  end
end
