require File.dirname(__FILE__) + '/../../spec_helper'
require 'archive/support/binary_stringio'

with_feature :encoding do
  describe "BinaryStringIO#set_encoding" do
    it "should be private" do
      lambda do
        BinaryStringIO.new.set_encoding('utf-8')
      end.should raise_error(NoMethodError)
    end
  end
end
