require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'

describe "Archive::Zip::Codec::Store::Decompress#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    StoreSpecs.compressed_data do |cd|
      Archive::Zip::Codec::Store::Decompress.open(cd) do |d|
        d.read(4)
        lambda { d.rewind }.should_not raise_error
        d.read.should == StoreSpecs.test_data
      end
    end
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::Store::Decompress.open(delegate) do |d|
      lambda { d.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
