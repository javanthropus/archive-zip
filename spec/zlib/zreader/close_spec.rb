require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'stringio'

describe "Zlib::ZReader.close" do
  it "closes the stream" do
    zr = Zlib::ZReader.new(StringIO.new)
    zr.close
    zr.closed?.should be_true
  end
end
