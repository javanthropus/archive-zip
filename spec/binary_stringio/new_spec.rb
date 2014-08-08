# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/binary_stringio'

describe "BinaryStringIO.new" do
  it "returns a new instance" do
    io = BinaryStringIO.new
    io.must_be_instance_of BinaryStringIO
    io.close
  end

  it "creates a decendent of StringIO" do
    io = BinaryStringIO.new
    io.must_be_kind_of StringIO
    io.close
  end

  # TODO:
  # This is lame.  Break this out as augmentation for the "returns a new
  # instance" test.
  it "takes the same arguments as StringIO.new" do
    BinaryStringIO.new.must_be_instance_of BinaryStringIO
    BinaryStringIO.new('').must_be_instance_of BinaryStringIO
    BinaryStringIO.new('', 'r').must_be_instance_of BinaryStringIO
    BinaryStringIO.new('', 'w').must_be_instance_of BinaryStringIO

    lambda { BinaryStringIO.new('', 'w', 42) }.must_raise ArgumentError
  end

  if Object.const_defined?(:Encoding)
    it "sets the external encoding to binary" do
      io = BinaryStringIO.new
      io.external_encoding.must_equal Encoding::ASCII_8BIT
    end
  end
end
