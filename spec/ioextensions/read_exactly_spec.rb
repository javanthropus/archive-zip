require File.dirname(__FILE__) + '/../../spec_helper'
require 'archive/support/ioextensions.rb'
require 'archive/support/binary_stringio'

describe "IOExtensions.read_exactly" do
  it "reads and returns length bytes from a given IO object" do
    io = BinaryStringIO.new('This is test data')
    IOExtensions.read_exactly(io, 4).should == 'This'
    IOExtensions.read_exactly(io, 13).should == ' is test data'
  end

  it "raises an error when too little data is available" do
    io = BinaryStringIO.new('This is test data')
    lambda do
      IOExtensions.read_exactly(io, 18)
    end.should raise_error(EOFError)
  end

  it "takes an optional buffer argument and fills it" do
    io = BinaryStringIO.new('This is test data')
    buffer = ''
    IOExtensions.read_exactly(io, 4, buffer)
    buffer.should == 'This'
    buffer = ''
    IOExtensions.read_exactly(io, 13, buffer)
    buffer.should == ' is test data'
  end

  it "empties the optional buffer before filling it" do
    io = BinaryStringIO.new('This is test data')
    buffer = ''
    IOExtensions.read_exactly(io, 4, buffer)
    buffer.should == 'This'
    IOExtensions.read_exactly(io, 13, buffer)
    buffer.should == ' is test data'
  end

  it "can read 0 bytes" do
    io = BinaryStringIO.new('This is test data')
    IOExtensions.read_exactly(io, 0).should == ''
  end

  it "retries partial reads" do
    io = mock('io')
    io.should_receive(:read).exactly(2).and_return('hello')
    IOExtensions.read_exactly(io, 10).should == 'hellohello'
  end
end
