require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/deflate'
require 'stringio'

describe "Archive::Zip::Codec::Deflate::Compress#close" do
  it "closes the stream" do
    c = Archive::Zip::Codec::Deflate::Compress.new(
      StringIO.new, Zlib::DEFAULT_COMPRESSION
    )
    c.close
    c.closed?.should be_true
  end

  it "closes the delegate stream by default" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    delegate.should_receive(:write).at_least(:once).and_return(1)
    c = Archive::Zip::Codec::Deflate::Compress.new(
      delegate, Zlib::DEFAULT_COMPRESSION
    )
    c.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    delegate.should_receive(:write).at_least(:once).and_return(1)
    c = Archive::Zip::Codec::Deflate::Compress.new(
      delegate, Zlib::DEFAULT_COMPRESSION
    )
    c.close(true)

    delegate = mock('delegate')
    delegate.should_not_receive(:close)
    delegate.should_receive(:write).at_least(:once).and_return(1)
    c = Archive::Zip::Codec::Deflate::Compress.new(
      delegate, Zlib::DEFAULT_COMPRESSION
    )
    c.close(false)
  end
end
