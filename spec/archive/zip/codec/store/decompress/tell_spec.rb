# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#tell" do
  it "returns the current position of the stream" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        d.tell.should == 0
        d.read(4)
        d.tell.should == 4
        d.read
        d.tell.should == 235
        d.rewind
        d.tell.should == 0
      end
    end
  end
end
