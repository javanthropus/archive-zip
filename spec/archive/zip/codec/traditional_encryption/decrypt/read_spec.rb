# encoding: UTF-8
require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'

describe "Archive::Zip::Codec::TraditionalEncryption::Decrypt#read" do
  it "calls the read method of the delegate" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:read).with(an_instance_of(Fixnum)).at_least(:once).and_return { |n| "\000" * n }
    # Use the following instead for now.
    delegate.should_receive(:read).twice.and_return("\000" * 12, nil)
    delegate.should_receive(:close).and_return(nil)
    Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |d|
      d.read
    end
  end

  it "decrypts data read from the delegate" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        d.read.should == TraditionalEncryptionSpecs.test_data
      end
    end
  end

  it "decrypts data read from a delegate that only returns 1 byte at a time" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      # Override ed.read to raise Errno::EAGAIN every other time it's called.
      class << ed
        alias :read_orig :read
        def read(length = nil, buffer = nil)
          read_orig(1, buffer)
        end
      end

      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        buffer = ''
        begin
          buffer << d.read
        rescue Errno::EAGAIN
          retry
        end
        buffer.should == TraditionalEncryptionSpecs.test_data
      end
    end
  end

  it "decrypts data read from a delegate that raises Errno::EAGAIN" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      # Override ed.read to raise Errno::EAGAIN every other time it's called.
      class << ed
        alias :read_orig :read
        def read(length = nil, buffer = nil)
          if @error_raised then
            @error_raised = false
            read_orig(length, buffer)
          else
            @error_raised = true
            raise Errno::EAGAIN
          end
        end
      end

      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        buffer = ''
        begin
          buffer << d.read
        rescue Errno::EAGAIN
          retry
        end
        buffer.should == TraditionalEncryptionSpecs.test_data
      end
    end
  end

  it "decrypts data read from a delegate that raises Errno::EINTR" do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      # Override ed.read to raise Errno::EINTR every other time it's called.
      class << ed
        alias :read_orig :read
        def read(length = nil, buffer = nil)
          if @error_raised then
            @error_raised = false
            read_orig(length, buffer)
          else
            @error_raised = true
            raise Errno::EINTR
          end
        end
      end

      Archive::Zip::Codec::TraditionalEncryption::Decrypt.open(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      ) do |d|
        buffer = ''
        begin
          buffer << d.read
        rescue Errno::EINTR
          retry
        end
        buffer.should == TraditionalEncryptionSpecs.test_data
      end
    end
  end
end
