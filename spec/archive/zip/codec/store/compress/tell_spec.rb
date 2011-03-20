# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/store'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::Store::Compress#tell" do
  it "returns the current position of the stream" do
    sio = BinaryStringIO.new
    Archive::Zip::Codec::Store::Compress.open(sio) do |c|
      c.tell.should == 0
      c.write('test1')
      c.tell.should == 5
      c.write('test2')
      c.tell.should == 10
      c.rewind
      c.tell.should == 0
    end
  end

  it "raises IOError on closed stream" do
    delegate = mock('delegate')
    delegate.should_receive(:close).once.and_return(nil)
    lambda do
      Archive::Zip::Codec::Store::Compress.open(delegate) { |c| c }.tell
    end.should raise_error(IOError)
  end
end
