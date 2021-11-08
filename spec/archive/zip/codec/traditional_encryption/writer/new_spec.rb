# encoding: UTF-8

require 'minitest/autorun'

require 'archive/zip/codec/traditional_encryption'

require_relative '../fixtures/classes'

describe 'Archive::Zip::Codec::TraditionalEncryption::Writer.new' do
  it 'returns a new instance' do
    TraditionalEncryptionSpecs.string_io do |sio|
      e = Archive::Zip::Codec::TraditionalEncryption::Writer.new(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      )
      _(e).must_be_instance_of(Archive::Zip::Codec::TraditionalEncryption::Writer)
      e.close
    end
  end

  it 'ensures the delegate will be closed by default' do
    TraditionalEncryptionSpecs.string_io do |sio|
      e = Archive::Zip::Codec::TraditionalEncryption::Writer.new(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime
      )
      e.close
      _(sio.closed?).must_equal true
    end
  end

  it 'allows the delegate to be left open' do
    TraditionalEncryptionSpecs.string_io do |sio|
      e = Archive::Zip::Codec::TraditionalEncryption::Writer.new(
        sio,
        TraditionalEncryptionSpecs.password,
        TraditionalEncryptionSpecs.mtime,
        autoclose: false
      )
      e.close
      _(sio.closed?).must_equal false
    end
  end
end
