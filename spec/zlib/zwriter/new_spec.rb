require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'stringio'

describe "Zlib::ZWriter.new" do
  it "returns a new instance" do
    Zlib::ZWriter.new(StringIO.new).class.should == Zlib::ZWriter
  end

  it "provides default settings for level, window_bits, mem_level, and strategy" do
    data = ZlibSpecs.test_data
    compressed_data = StringIO.new
    zw = Zlib::ZWriter.new(compressed_data)
    zw.write(data)
    zw.close

    compressed_data.string.should == ZlibSpecs.compressed_data
  end

  it "allows level to be set" do
    data = ZlibSpecs.test_data
    compressed_data = StringIO.new
    zw = Zlib::ZWriter.new(compressed_data, Zlib::NO_COMPRESSION)
    zw.write(data)
    zw.close

    compressed_data.string.should == ZlibSpecs.compressed_data_nocomp
  end

  it "allows window_bits to be set" do
    data = ZlibSpecs.test_data
    compressed_data = StringIO.new
    zw = Zlib::ZWriter.new(compressed_data, nil, 8)
    zw.write(data)
    zw.close

    compressed_data.string.should == ZlibSpecs.compressed_data_minwin
  end

  it "allows mem_level to be set" do
    data = ZlibSpecs.test_data
    compressed_data = StringIO.new
    zw = Zlib::ZWriter.new(compressed_data, nil, nil, 1)
    zw.write(data)
    zw.close

    compressed_data.string.should == ZlibSpecs.compressed_data_minmem
  end

  it "allows strategy to be set" do
    data = ZlibSpecs.test_data
    compressed_data = StringIO.new
    zw = Zlib::ZWriter.new(compressed_data, nil, nil, nil, Zlib::HUFFMAN_ONLY)
    zw.write(data)
    zw.close

    compressed_data.string.should == ZlibSpecs.compressed_data_huffman
  end
end