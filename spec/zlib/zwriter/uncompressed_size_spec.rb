require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'archive/support/binary_stringio'

describe "Zlib::ZWriter#uncompressed_size" do
  it "returns the number of bytes of uncompressed data" do
    compressed_data = BinaryStringIO.new
    closed_zw = Zlib::ZWriter.open(compressed_data, nil, -15) do |zw|
      zw.sync = true
      zw.write(ZlibSpecs.test_data)
      zw.uncompressed_size.should == 235
      zw
    end
    closed_zw.uncompressed_size.should == 235
  end
end
