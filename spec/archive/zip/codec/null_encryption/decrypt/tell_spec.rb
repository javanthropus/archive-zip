# encoding: UTF-8

require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/null_encryption'

describe "Archive::Zip::Codec::NullEncryption::Decrypt#tell" do
  it "returns the current position of the stream" do
    NullEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::NullEncryption::Decrypt.open(ed) do |d|
        d.tell.should == 0
        d.read(4)
        d.tell.should == 4
        d.read
        d.tell.should == 235
        d.rewind
        d.tell.should == 0
      end
    end
  end
end
