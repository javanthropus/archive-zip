# encoding: UTF-8

require 'archive/support/time'
require 'archive/support/zlib'
require 'archive/zip/codec'
require 'io/like_helpers/delegated_io'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::TraditionalEncryption is a handle for the traditional
  # encryption codec.
  class TraditionalEncryption
    # Archive::Zip::Codec::TraditionalEncryption::Base provides some basic
    # methods which are shared between
    # Archive::Zip::Codec::TraditionalEncryption::Writer and
    # Archive::Zip::Codec::TraditionalEncryption::Reader.
    #
    # Do not use this class directly.
    class Base < IO::LikeHelpers::DelegatedIO
      # Creates a new instance of this class.  _delegate must be an IO-like
      # object to be used as a delegate for IO operations.  _password_ should be
      # the encryption key.  _mtime_ must be the last modified time of the entry
      # to be encrypted/decrypted.
      def initialize(delegate, password, mtime, autoclose: true)
        super(delegate, autoclose: autoclose)
        @password = password.nil? ? '' : password
        @mtime = mtime

        initialize_keys
      end

      # Allows resetting this object and the delegate object back to the
      # beginning of the stream or reporting the current position in the stream.
      #
      # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is
      # either IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_
      # is IO::SEEK_SEK and the delegate object does not respond to the _rewind_
      # method.
      def seek(amount, whence = IO::SEEK_SET)
        assert_open
        raise Errno::ESPIPE if amount != 0 || whence == IO::SEEK_END

        if whence == IO::SEEK_SET
          super
          initialize_keys
        end

        @bytes_processed
      end

      private

      # Initializes the keys used for encrypting/decrypting data by setting the
      # keys to well known values and then processing them with the password.
      def initialize_keys
        @key0 = 0x12345678
        @key1 = 0x23456789
        @key2 = 0x34567890
        @password.each_char { |char| update_keys(char) }

        @bytes_processed = 0
        nil
      end

      # Updates the keys following the ZIP specification using _char_, which
      # must be a single byte String.
      def update_keys(char)
        # For some reason not explained in the ZIP specification but discovered
        # in the source for InfoZIP, the old CRC value must first have its bits
        # flipped before processing.  The new CRC value must have its bits
        # flipped as well for storage and later use.  This applies to the
        # handling of @key0 and @key2.
        @key0 = ~Zlib.crc32(char, ~@key0)
        @key1 = ((@key1 + (@key0 & 0xff)) * 134775813 + 1) & 0xffffffff
        @key2 = ~Zlib.crc32((@key1 >> 24).chr, ~@key2)
        nil
      end

      # Returns the next decryption byte based on the current keys.
      def decrypt_byte
        temp = (@key2 | 2) & 0x0000ffff
        ((temp * (temp ^ 1)) >> 8) & 0x000000ff
      end
    end

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
          (10.times.map { |_| rand(256) } + @mtime.to_dos_time.pack[0, 2].bytes)
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
      def read(length, buffer: nil)
        # This short circuits if the header has already been read.
        result = read_header
        return result if Symbol === result

        result = super
        return result if Symbol === result

        if buffer.nil?
          buffer = result
          length = buffer.bytesize
        else
          length = result
        end

        buffer[0, length].to_enum(:each_byte).each_with_index do |byte, idx|
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

    # The last modified time of the entry to be processed.  Set this before
    # calling #encryptor or #decryptor.
    attr_accessor :mtime

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Writer object using that
    # class' open method.
    def encryptor(io, password, &b)
      Writer.open(io, password, mtime, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Reader object using that
    # class' open method.
    def decryptor(io, password, &b)
      Reader.open(io, password, mtime, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns an integer which indicates the version of the official ZIP
    # specification which introduced support for this encryption codec.
    def version_needed_to_extract
      0x0014
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns an integer representing the general purpose flags of a ZIP archive
    # entry using this encryption codec.
    def general_purpose_flags
      0b0000000000000001
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns the size of the encryption header in bytes.
    def header_size
      12
    end
  end
end; end; end
