# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress#write" do
  it "calls the write method of the delegate" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).once.and_return(nil)
    Archive::Zip::Codec::Store::Compress.open(delegate) do |c|
      c.write(StoreSpecs.test_data)
    end
  end

  it "passes data through unmodified" do
    compressed_data = BinaryStringIO.new
    Archive::Zip::Codec::Store::Compress.open(compressed_data) do |c|
      c.write(StoreSpecs.test_data)
    end
    compressed_data.string.should == StoreSpecs.compressed_data
  end
end
