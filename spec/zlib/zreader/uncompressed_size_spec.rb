# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'

describe "Zlib::ZReader#uncompressed_size" do
  it "returns the number of bytes of uncompressed data" do
    closed_zr = ZlibSpecs.compressed_data_raw do |compressed_data|
      Zlib::ZReader.open(compressed_data, -15) do |zr|
        zr.read
        zr.uncompressed_size.should == 235
        zr
      end
    end
    closed_zr.uncompressed_size.should == 235
  end
end
