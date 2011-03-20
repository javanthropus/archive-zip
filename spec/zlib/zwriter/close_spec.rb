# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter.close" do
  it "closes the stream" do
    zw = Zlib::ZWriter.new(BinaryStringIO.new)
    zw.close
    zw.closed?.should be_true
  end
end
