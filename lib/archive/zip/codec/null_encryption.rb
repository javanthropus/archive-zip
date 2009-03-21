require 'archive/support/io-like'
require 'archive/zip/codec'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::NullEncryption is a handle for an encryption codec
  # which passes data through itself unchanged.
  class NullEncryption
    # Archive::Zip::Codec::NullEncryption::Encrypt is a writable, IO-like object
    # which writes all data written to it directly to a delegate IO object.  A
    # _close_ method is also provided which can optionally closed the delegate
    # object.
    class Encrypt
      include IO::Like

      # Creates a new instance of this class with the given argument using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io)
        encrypt_io = new(io)
        return encrypt_io unless block_given?

        begin
          yield(encrypt_io)
        ensure
          encrypt_io.close unless encrypt_io.closed?
        end
      end

      # Creates a new instance of this class using _io_ as a data sink.  _io_
      # must be writable and must provide a write method as IO does or errors
      # will be raised when performing write operations.
      #
      # The _flush_size_ attribute is set to <tt>0</tt> by default under the
      # assumption that _io_ is already buffered.
      def initialize(io)
        @io = io
        # Assume that the delegate IO object is already buffered.
        self.flush_size = 0
      end

      # Closes this object so that further write operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data sink will
      # also be closed using its close method.
      def close(close_delegate = true)
        super()
        @io.close if close_delegate
      end

      private

      # Writes _string_ to the delegate IO object and returns the result.
      def unbuffered_write(string)
        @io.write(string)
      end
    end

    # Archive::Zip::Codec::NullEncryption::Decrypt is a readable, IO-like object
    # which reads data directly from a delegate IO object, making no changes.  A
    # _close_ method is also provided which can optionally closed the delegate
    # object.
    class Decrypt
      include IO::Like

      # Creates a new instance of this class with the given argument using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io)
        decrypt_io = new(io)
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
      # method, this class' rewind method will be enabled.
      #
      # The _fill_size_ attribute is set to <tt>0</tt> by default under the
      # assumption that _io_ is already buffered.
      def initialize(io)
        @io = io
        # Assume that the delegate IO object is already buffered.
        self.fill_size = 0
      end

      # Closes this object so that further write operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data source
      # will also be closed using its close method.
      def close(close_delegate = true)
        super()
        @io.close if close_delegate
      end

      private

      # Reads and returns at most _length_ bytes from the delegate IO object.
      #
      # Raises EOFError if there is no data to read.
      def unbuffered_read(length)
        buffer = @io.read(length)
        raise EOFError, 'end of file reached' if buffer.nil?

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
        unless @io.respond_to?(:rewind) then
          raise Errno::ESPIPE, 'Illegal seek'
        end
        @io.rewind
      end
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::NullEncryption::Encrypt object using that class' open
    # method.
    def encryptor(io, password, &b)
      Encrypt.open(io, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::NullEncryption::Decrypt object using that class' open
    # method.
    def decryptor(io, password, &b)
      Decrypt.open(io, &b)
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
      0b0000000000000000
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns the size of the encryption header in bytes.
    def header_size
      0
    end
  end
end; end; end
