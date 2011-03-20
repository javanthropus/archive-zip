# encoding: UTF-8
require File.dirname(__FILE__) + '/../../spec_helper'
require 'archive/support/binary_stringio'

describe "BinaryStringIO.new" do
  it "returns a new instance" do
    io = BinaryStringIO.new
    io.class.should == BinaryStringIO
    io.close
  end

  it "creates a decendent of StringIO" do
    io = BinaryStringIO.new
    io.should be_kind_of StringIO
    io.close
  end

  it "takes the same arguments as StringIO.new" do
    lambda { BinaryStringIO.new }.should_not raise_error(ArgumentError)
    lambda { BinaryStringIO.new('') }.should_not raise_error(ArgumentError)
    lambda { BinaryStringIO.new('', 'r') }.should_not raise_error(ArgumentError)
    lambda { BinaryStringIO.new('', 'w') }.should_not raise_error(ArgumentError)

    lambda { BinaryStringIO.new('', 'w', 42) }.should raise_error(ArgumentError)
  end

  with_feature :encoding do
    it "sets the external encoding to binary" do
      io = BinaryStringIO.new
      io.external_encoding.should == Encoding::ASCII_8BIT
    end
  end
end
