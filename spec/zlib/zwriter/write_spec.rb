require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/support/zlib'
require 'stringio'

describe "Zlib::ZWriter#write" do
  it "calls the write method of the delegate" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    Zlib::ZWriter.open(delegate) do |zw|
      zw.write(ZlibSpecs.test_data)
    end
  end

  it "compresses data" do
    compressed_data = StringIO.new
    Zlib::ZWriter.open(compressed_data) do |zw|
      zw.write(ZlibSpecs.test_data)
    end
    compressed_data.string.should == ZlibSpecs.compressed_data
  end
end
