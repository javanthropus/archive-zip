# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#read" do
  it "calls the read method of the delegate" do
    delegate = mock('delegate')
    delegate.should_receive(:read).and_return(nil)
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::Store::Decompress.open(delegate) do |d|
      d.read
    end
  end

  it "passes data through unmodified" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        d.read.should == StoreSpecs.test_data
      end
    end
  end
end
