# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#compressed_size" do
  it "returns the number of bytes of compressed data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, -15) do |zw|
      zw.sync = true
      zw.write(ZlibSpecs.test_data)
      zw.compressed_size.should >= 0
      zw
    end
    closed_zw.compressed_size.should == 160
  end
end
