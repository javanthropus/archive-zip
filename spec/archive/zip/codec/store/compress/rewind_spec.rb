require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'stringio'

describe "Archive::Zip::Codec::Store::Compress#rewind" do
  it "can rewind the stream when the delegate responds to rewind" do
    sio = StringIO.new
    Archive::Zip::Codec::Store::Compress.open(sio) do |c|
      c.write('test')
      lambda { c.rewind }.should_not raise_error
      c.write(StoreSpecs.test_data)
    end
    sio.string.should == StoreSpecs.compressed_data
  end

  it "raises Errno::EINVAL when attempting to rewind the stream when the delegate does not respond to rewind" do
    delegate = mock('delegate')
    delegate.should_receive(:close).once.and_return(nil)
    Archive::Zip::Codec::Store::Compress.open(delegate) do |c|
      lambda { c.rewind }.should raise_error(Errno::EINVAL)
    end
  end
end
