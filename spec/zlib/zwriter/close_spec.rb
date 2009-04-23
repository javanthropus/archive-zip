require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'stringio'

describe "Zlib::ZWriter.close" do
  it "closes the stream" do
    zw = Zlib::ZWriter.new(StringIO.new)
    zw.close
    zw.closed?.should be_true
  end
end
