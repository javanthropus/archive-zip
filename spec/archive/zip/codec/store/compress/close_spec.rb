# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress#close" do
  it "closes the stream" do
    c = Archive::Zip::Codec::Store::Compress.new(BinaryStringIO.new)
    c.close
    c.closed?.should be_true
  end

  it "closes the delegate stream by default" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    c = Archive::Zip::Codec::Store::Compress.new(delegate)
    c.close
  end

  it "optionally leaves the delegate stream open" do
    delegate = mock('delegate')
    delegate.should_receive(:close).and_return(nil)
    c = Archive::Zip::Codec::Store::Compress.new(delegate)
    c.close(true)

    delegate = mock('delegate')
    delegate.should_not_receive(:close)
    c = Archive::Zip::Codec::Store::Compress.new(delegate)
    c.close(false)
  end
end
