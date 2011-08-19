# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::NullEncryption::Encrypt#tell" do
  it "returns the current position of the stream" do
    sio = BinaryStringIO.new
    Archive::Zip::Codec::NullEncryption::Encrypt.open(sio) do |e|
      e.tell.should == 0
      e.write('test1')
      e.tell.should == 5
      e.write('test2')
      e.tell.should == 10
      e.rewind
      e.tell.should == 0
    end
  end

  it "raises IOError on closed stream" do
    delegate = mock('delegate')
    delegate.should_receive(:close).once.and_return(nil)
    lambda do
      Archive::Zip::Codec::NullEncryption::Encrypt.open(delegate) { |e| e }.tell
    end.should raise_error(IOError)
  end
end
