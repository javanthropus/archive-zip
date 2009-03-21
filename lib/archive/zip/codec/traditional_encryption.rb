require 'archive/support/io-like'
require 'archive/support/time'
require 'archive/support/zlib'
require 'archive/zip/codec'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::TraditionalEncryption is a handle for the traditional
  # encryption codec.
  class TraditionalEncryption
    # Archive::Zip::Codec::TraditionalEncryption::Base provides some basic
    # methods which are shared between
    # Archive::Zip::Codec::TraditionalEncryption::Encrypt and
    # Archive::Zip::Codec::TraditionalEncryption::Decrypt.
    #
    # Do not use this class directly.
    class Base
      # Creates a new instance of this class.  _io_ must be an IO-like object to
      # be used as a delegate for IO operations.  _password_ should be the
      # encryption key.  _mtime_ must be the last modified time of the entry to
      # be encrypted/decrypted.
      def initialize(io, password, mtime)
        @io = io
        @password = password.nil? ? '' : password
        @mtime = mtime
        initialize_keys
      end

      protected

      # The delegate IO-like object.
      attr_reader :io
      # The encryption key.
      attr_reader :password
      # The last modified time of the entry being encrypted.  This is used in
      # the entryption header as a way to check the password.
      attr_reader :mtime

      private

      # Initializes the keys used for encrypting/decrypting data by setting the
      # keys to well known values and then processing them with the password.
      def initialize_keys
        @key0 = 0x12345678
        @key1 = 0x23456789
        @key2 = 0x34567890
        @password.each_byte { |byte| update_keys(byte.chr) }
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
        #
        # NOTE: XOR'ing with 0xffffffff is used instead of simple bit negation
        # in case this is run on a platform with a native integer size of
        # something other than 32 bits.
        @key0 = Zlib.crc32(char, @key0 ^ 0xffffffff) ^ 0xffffffff
        @key1 = ((@key1 + (@key0 & 0xff)) * 134775813 + 1) & 0xffffffff
        @key2 = Zlib.crc32((@key1 >> 24).chr, @key2 ^ 0xffffffff) ^ 0xffffffff
        nil
      end

      # Returns the next decryption byte based on the current keys.
      def decrypt_byte
        temp = (@key2 | 2) & 0x0000ffff
        ((temp * (temp ^ 1)) >> 8) & 0x000000ff
      end
    end

    # Archive::Zip::Codec::TraditionalEncryption::Encrypt is a writable, IO-like
    # object which encrypts data written to it using the traditional encryption
    # algorithm as documented in the ZIP specification and writes the result to
    # a delegate IO object.  A _close_ method is also provided which can
    # optionally close the delegate object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::TraditionalEncryption#compressor method.
    class Encrypt < Base
      include IO::Like

      # Creates a new instance of this class with the given argument using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io, password, mtime)
        encrypt_io = new(io, password, mtime)
        return encrypt_io unless block_given?

        begin
          yield(encrypt_io)
        ensure
          encrypt_io.close unless encrypt_io.closed?
        end
      end

      # Creates a new instance of this class using _io_ as a data sink.  _io_
      # must be writable and must provide a write method as IO does or errors
      # will be raised when performing write operations.  _password_ should be
      # the encryption key.  _mtime_ must be the last modified time of the entry
      # to be encrypted/decrypted.
      #
      # The _flush_size_ attribute is set to <tt>0</tt> by default under the
      # assumption that _io_ is already buffered.
      def initialize(io, password, mtime)
        super(io, password, mtime)

        # Assume that the delegate IO object is already buffered.
        self.flush_size = 0
      end

      # Closes this object so that further write operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data sink will
      # also be closed using its close method.
      def close(close_delegate = true)
        super()
        io.close if close_delegate
      end

      private

      # Extend the inherited initialize_keys method to further initialize the
      # keys by encrypting and writing a 12 byte header to the delegate IO
      # object.
      def initialize_keys
        super

        # Create and encrypt a 12 byte header to protect the encrypted file data
        # from attack.  The first 10 bytes are random, and the lat 2 bytes are
        # the low order word of the last modified time of the entry in DOS
        # format.
        10.times do
          unbuffered_write(rand(256).chr)
        end
        time = mtime.to_dos_time.to_i
        unbuffered_write((time & 0xff).chr)
        unbuffered_write(((time >> 8) & 0xff).chr)
        nil
      end

      # Encrypts and writes _string_ to the delegate IO object.  Returns the
      # number of bytes of _string_ written.  If _string_ is not a String, it is
      # converted into one using its _to_s_ method.
      def unbuffered_write(string)
        string = string.to_s
        bytes_written = 0
        string.each_byte do |byte|
          temp = decrypt_byte
          break unless io.write((byte ^ temp).chr) > 0
          bytes_written += 1
          update_keys(byte.chr)
        end
        bytes_written
      end
    end

    # Archive::Zip::Codec::TraditionalEncryption::Decrypt is a readable, IO-like
    # object which decrypts data data it reads from a delegate IO object using
    # the traditional encryption algorithm as documented in the ZIP
    # specification.  A _close_ method is also provided which can optionally
    # close the delegate object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::TraditionalEncryption#decompressor method.
    class Decrypt < Base
      include IO::Like

      # Creates a new instance of this class with the given argument using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io, password, mtime)
        decrypt_io = new(io, password, mtime)
        return decrypt_io unless block_given?

        begin
          yield(decrypt_io)
        ensure
          decrypt_io.close unless decrypt_io.closed?
        end
      end

      # Creates a new instance of this class using _io_ as a data source.  _io_
      # must be readable and provide a read method as IO does or errors will be
      # raised when performing read operations.  If _io_ provides a rewind
      # method, this class' rewind method will be enabled.  _password_ should be
      # the encryption key.  _mtime_ must be the last modified time of the entry
      # to be encrypted/decrypted.
      #
      # The _fill_size_ attribute is set to <tt>0</tt> by default under the
      # assumption that _io_ is already buffered.
      def initialize(io, password, mtime)
        super(io, password, mtime)

        # Assume that the delegate IO object is already buffered.
        self.fill_size = 0
      end

      # Closes this object so that further write operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data source
      # will also be closed using its close method.
      def close(close_delegate = true)
        super()
        io.close if close_delegate
      end

      private

      # Extend the inherited initialize_keys method to further initialize the
      # keys by encrypting and writing a 12 byte header to the delegate IO
      # object.
      def initialize_keys
        super

        # Decrypt the 12 byte header.
        unbuffered_read(12)
        nil
      end

      # Reads, decrypts, and returns at most _length_ bytes from the delegate IO
      # object.
      #
      # Raises EOFError if there is no data to read.
      def unbuffered_read(length)
        buffer = io.read(length)
        raise EOFError, 'end of file reached' if buffer.nil?

        (0 ... buffer.size).each do |i|
          buffer[i] = (buffer[i] ^ decrypt_byte)
          update_keys(buffer[i].chr)
        end
        buffer
      end

      # Allows resetting this object and the delegate object back to the
      # beginning of the stream.  _offset_ must be <tt>0</tt> and _whence_ must
      # be IO::SEEK_SET or an error will be raised.  The delegate object must
      # respond to the _rewind_ method or an error will be raised.
      def unbuffered_seek(offset, whence = IO::SEEK_SET)
        unless offset == 0 && whence == IO::SEEK_SET then
          raise Errno::EINVAL, 'Invalid argument'
        end
        unless io.respond_to?(:rewind) then
          raise Errno::ESPIPE, 'Illegal seek'
        end
        io.rewind
        initialize_keys
        0
      end
    end

    # The last modified time of the entry to be processed.  Set this before
    # calling #encryptor or #decryptor.
    attr_accessor :mtime

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Encrypt object using that
    # class' open method.
    def encryptor(io, password, &b)
      Encrypt.open(io, password, mtime, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Decrypt object using that
    # class' open method.
    def decryptor(io, password, &b)
      Decrypt.open(io, password, mtime, &b)
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
