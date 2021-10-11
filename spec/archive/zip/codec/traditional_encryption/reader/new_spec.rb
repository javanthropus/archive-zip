# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/traditional_encryption'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::TraditionalEncryption::Reader.new' do
  it 'returns a new instance' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      d = Archive::Zip::Codec::TraditionalEncryption::Reader.new(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      )
      d.must_be_instance_of(Archive::Zip::Codec::TraditionalEncryption::Reader)
      d.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      d = Archive::Zip::Codec::TraditionalEncryption::Reader.new(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      )
      d.close
      ed.closed?.must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    TraditionalEncryptionSpecs.encrypted_data do |ed|
      d = Archive::Zip::Codec::TraditionalEncryption::Reader.new(
        ed,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime,
        autoclose: false
      )
      d.close
      ed.closed?.must_equal false
    end
  end
end
