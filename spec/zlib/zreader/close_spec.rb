# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZReader.close" do
  it "closes the stream" do
    zr = Zlib::ZReader.new(BinaryStringIO.new)
    zr.close
    zr.closed?.should be_true
  end
end
