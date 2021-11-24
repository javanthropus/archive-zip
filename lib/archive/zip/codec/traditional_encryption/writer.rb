# encoding: UTF-8

require 'archive/zip/codec/traditional_encryption/base'
require 'archive/zip/dos_time'

module Archive; class Zip; module Codec; class TraditionalEncryption
# Archive::Zip::Codec::TraditionalEncryption::Writer is a writable, IO-like
# object which encrypts data written to it using the traditional encryption
# algorithm as documented in the ZIP specification and writes the result to
# a delegate IO object.  A _close_ method is also provided which can
# optionally close the delegate object.
#
# Instances of this class should only be accessed via the
# Archive::Zip::Codec::TraditionalEncryption#compressor method.
class Writer < Base
  def initialize(delegate, password, mtime, autoclose: true)
    super

    # A 12 byte header to protect the encrypted file data from attack.  The
    # first 10 bytes are random, and the last 2 bytes are the low order word
    # in little endian byte order of the last modified time of the entry in
    # DOS format.
    @header =
      (10.times.map { |_| rand(256) } + [DOSTime.new(@mtime).to_i].pack('V')[0, 2].bytes)
      .map do |byte|
        crypt_char = (byte ^ decrypt_byte).chr
        update_keys(byte.chr)
        crypt_char
      end
      .join
  end

  # Encrypts and writes _string_ to the delegate IO object.  Returns the
  # number of bytes of _string_ written.
  def write(buffer, length: buffer.bytesize)
    result = write_header
    return result if Symbol === result

    buffer = buffer[0, length] if length < buffer.bytesize
    buffer.to_enum(:each_byte).each_with_index do |byte, idx|
      result = super((byte ^ decrypt_byte).chr)
      if Symbol === result
        return idx if idx > 0
        return result
      end
      update_keys(byte.chr)
      @bytes_processed += 1
    end

    buffer.bytesize
  end

  private

  def write_header
    while @header_idx < @header.size do
      result = delegate.write(@header[@header_idx..-1])
      return result if Symbol === result

      @header_idx += result
    end

    nil
  end

  def initialize_keys
    super
    @header_idx = 0
  end
end
end; end; end; end
