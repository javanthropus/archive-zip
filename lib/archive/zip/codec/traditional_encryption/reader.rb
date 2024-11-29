# encoding: UTF-8

require 'archive/zip/codec/traditional_encryption/base'

module Archive; class Zip; module Codec; class TraditionalEncryption
# Archive::Zip::Codec::TraditionalEncryption::Reader is a readable, IO-like
# object which decrypts data data it reads from a delegate IO object using
# the traditional encryption algorithm as documented in the ZIP
# specification.  A _close_ method is also provided which can optionally
# close the delegate object.
#
# Instances of this class should only be accessed via the
# Archive::Zip::Codec::TraditionalEncryption#decompressor method.
class Reader < Base
  # Reads, decrypts, and returns at most _length_ bytes from the delegate IO
  # object.
  #
  # Raises EOFError if there is no data to read.
  def read(length, buffer: nil, buffer_offset: 0)
    # This short circuits if the header has already been read.
    result = read_header
    return result if Symbol === result

    result = super
    return result if Symbol === result

    if buffer.nil?
      buffer = result
      buffer_offset = 0
      length = buffer.bytesize
    else
      length = result
    end

    buffer[buffer_offset, length].to_enum(:each_byte).each_with_index do |byte, idx|
      buffer[idx] = (byte ^ decrypt_byte).chr
      update_keys(buffer[idx])
    end
    @bytes_processed += length

    result
  end

  private

  def read_header
    while @header_bytes_needed > 0 do
      result = delegate.read(@header_bytes_needed)
      return result if Symbol === result

      result.each_byte do |byte|
        update_keys((byte ^ decrypt_byte).chr)
      end
      @header_bytes_needed -= result.bytesize
    end

    nil
  end

  def initialize_keys
    super
    @header_bytes_needed = 12
  end
end
end; end; end; end
