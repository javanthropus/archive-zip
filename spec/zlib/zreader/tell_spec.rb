# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'

describe "Zlib::ZReader#tell" do
  it "returns the current position of the stream" do
    ZlibSpecs.compressed_data do |cd|
      Zlib::ZReader.open(cd) do |zr|
        zr.tell.should == 0
        zr.read(4)
        zr.tell.should == 4
        zr.read
        zr.tell.should == 235
        zr.rewind
        zr.tell.should == 0
      end
    end
  end
end
