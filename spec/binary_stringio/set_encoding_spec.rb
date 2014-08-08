# encoding: UTF-8

require 'minitest/autorun'

require 'archive/support/binary_stringio'

if Object.const_defined?(:Encoding)
  describe "BinaryStringIO#set_encoding" do
    it "should be private" do
      lambda do
        BinaryStringIO.new.set_encoding('utf-8')
      end.must_raise NoMethodError
    end
  end
end
