require File.dirname(__FILE__) + '/../../../../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'archive/zip/codec/traditional_encryption'
require 'archive/support/binary_stringio'

describe "Archive::Zip::Codec::TraditionalEncryption::Encrypt#write" do
  it "calls the write method of the delegate" do
    delegate = mock('delegate')
    # RSpec's mocking facility supposedly supports this, but MSpec's does not as
    # of version 1.5.10.
    #delegate.should_receive(:write).with(an_instance_of(String)).at_least(:once).and_return { |s| s.length }
    # Use the following instead for now.
    delegate.should_receive(:write).at_least(:once).and_return(1)
    delegate.should_receive(:close).once.and_return(nil)
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      delegate,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write(TraditionalEncryptionSpecs.test_data)
    end
  end

  it "writes encrypted data to the delegate" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write(TraditionalEncryptionSpecs.test_data)
    end
    encrypted_data.string.should == TraditionalEncryptionSpecs.encrypted_data
  end

  it "writes encrypted data to a delegate that only performs partial writes" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    # Override encrypted_data.write to perform writes 1 byte at a time.
    class << encrypted_data
      alias :write_orig :write
      def write(buffer)
        write_orig(buffer.slice(0, 1))
      end
    end

    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      e.write(TraditionalEncryptionSpecs.test_data)
    end
    encrypted_data.string.should == TraditionalEncryptionSpecs.encrypted_data
  end

  it "writes encrypted data to a delegate that raises Errno::EAGAIN" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    # Override encrypted_data.write to raise Errno::EAGAIN every other time it's
    # called.
    class << encrypted_data
      alias :write_orig :write
      def write(buffer)
        if @error_raised then
          @error_raised = false
          write_orig(buffer)
        else
          @error_raised = true
          raise Errno::EAGAIN
        end
      end
    end

    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      begin
        e.write(TraditionalEncryptionSpecs.test_data)
      rescue Errno::EAGAIN
        retry
      end
    end
    encrypted_data.string.should == TraditionalEncryptionSpecs.encrypted_data
  end

  it "writes encrypted data to a delegate that raises Errno::EINTR" do
    # Ensure repeatable test data is used for encryption header.
    srand(0)
    encrypted_data = BinaryStringIO.new
    # Override encrypted_data.write to raise Errno::EINTR every other time it's
    # called.
    class << encrypted_data
      alias :write_orig :write
      def write(buffer)
        if @error_raised then
          @error_raised = false
          write_orig(buffer)
        else
          @error_raised = true
          raise Errno::EINTR
        end
      end
    end

    Archive::Zip::Codec::TraditionalEncryption::Encrypt.open(
      encrypted_data,
      TraditionalEncryptionSpecs.password,
      TraditionalEncryptionSpecs.mtime
    ) do |e|
      begin
        e.write(TraditionalEncryptionSpecs.test_data)
      rescue Errno::EINTR
        retry
      end
    end
    encrypted_data.string.should == TraditionalEncryptionSpecs.encrypted_data
  end
end
