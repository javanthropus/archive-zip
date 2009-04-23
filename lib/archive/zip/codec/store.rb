require 'archive/support/io-like'
require 'archive/zip/codec'
require 'archive/zip/data_descriptor'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::Store is a handle for the store-unstore (no
  # compression) codec.
  class Store
    # Archive::Zip::Codec::Store::Compress is simply a writable, IO-like wrapper
    # around a writable, IO-like object which provides a CRC32 checksum of the
    # data written through it as well as the count of the total amount of data.
    # A _close_ method is also provided which can optionally close the delegate
    # object.  In addition a convenience method is provided for generating
    # DataDescriptor objects based on the data which is passed through this
    # object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::Store#compressor method.
    class Compress
      include IO::Like

      # Creates a new instance of this class with the given argument using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io)
        store_io = new(io)
        return store_io unless block_given?

        begin
          yield(store_io)
        ensure
          store_io.close unless store_io.closed?
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
        @crc32 = 0
        @uncompressed_size = 0
        # Assume that the delegate IO object is already buffered.
        self.flush_size = 0
      end

      # Closes this object so that further write operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data sink will
      # also be closed using its close method.
      def close(close_delegate = true)
        super()
        @io.close if close_delegate
        nil
      end

      # Returns an instance of Archive::Zip::DataDescriptor with information
      # regarding the data which has passed through this object to the delegate
      # object.  The close or flush methods should be called before using this
      # method in order to ensure that any possibly buffered data is flushed to
      # the delegate object; otherwise, the contents of the data descriptor may
      # be inaccurate.
      def data_descriptor
        DataDescriptor.new(
          @crc32,
          @uncompressed_size,
          @uncompressed_size
        )
      end

      private

      # Writes _string_ to the delegate object and returns the number of bytes
      # actually written.  Updates the uncompressed_size and crc32 attributes as
      # a side effect.
      def unbuffered_write(string)
        bytes_written = @io.write(string)
        @uncompressed_size += bytes_written
        @crc32 = Zlib.crc32(string.slice(0, bytes_written), @crc32)
        bytes_written
      end
    end

    # Archive::Zip::Codec::Store::Decompress is a readable, IO-like wrapper
    # around a readable, IO-like object which provides a CRC32 checksum of the
    # data read through it as well as the count of the total amount of data.  A
    # _close_ method is also provided which can optionally close the delegate
    # object.  In addition a convenience method is provided for generating
    # DataDescriptor objects based on the data which is passed through this
    # object.
    #
    # Instances of this class should only be accessed via the
    # Archive::Zip::Codec::Store#decompressor method.
    class Decompress
      include IO::Like

      # Creates a new instance of this class with the given arguments using #new
      # and then passes the instance to the given block.  The #close method is
      # guaranteed to be called after the block completes.
      #
      # Equivalent to #new if no block is given.
      def self.open(io)
        unstore_io = new(io)
        return unstore_io unless block_given?

        begin
          yield(unstore_io)
        ensure
          unstore_io.close unless unstore_io.closed?
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
        @crc32 = 0
        @uncompressed_size = 0
        # Assume that the delegate IO object is already buffered.
        self.fill_size = 0
      end

      # Closes this object so that further read operations will fail.  If
      # _close_delegate_ is +true+, the delegate object used as a data source
      # will also be closed using its close method.
      def close(close_delegate = true)
        super()
        @io.close if close_delegate
        nil
      end

      # Returns an instance of Archive::Zip::DataDescriptor with information
      # regarding the data which has passed through this object from the
      # delegate object.  It is recommended to call the close method before
      # calling this in order to ensure that no further read operations change
      # the state of this object.
      def data_descriptor
        DataDescriptor.new(
          @crc32,
          @uncompressed_size,
          @uncompressed_size
        )
      end

      private

      # Returns at most _length_ bytes from the delegate object.  Updates the
      # uncompressed_size and crc32 attributes as a side effect.
      def unbuffered_read(length)
        buffer = @io.read(length)
        raise EOFError, 'end of file reached' if buffer.nil?

        @uncompressed_size += buffer.length
        @crc32 = Zlib.crc32(buffer, @crc32)
        buffer
      end

      # Allows resetting this object and the delegate object back to the
      # beginning of the stream.  _offset_ must be <tt>0</tt> and _whence_ must
      # be IO::SEEK_SET or an error will be raised.  The delegate object must
      # respond to the _rewind_ method or an error will be raised.  The
      # uncompressed_size and crc32 attributes are reinitialized as a side
      # effect.
      def unbuffered_seek(offset, whence = IO::SEEK_SET)
        unless offset == 0 && whence == IO::SEEK_SET then
          raise Errno::EINVAL, 'Invalid argument'
        end
        unless @io.respond_to?(:rewind) then
          raise Errno::ESPIPE, 'Illegal seek'
        end
        @io.rewind
        @crc32 = 0
        @uncompressed_size = 0
      end
    end

    # The numeric identifier assigned to this compresion codec by the ZIP
    # specification.
    ID = 0

    # Register this compression codec.
    COMPRESSION_CODECS[ID] = self

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Creates a new instance of this class.  _general_purpose_flags_ is not
    # used.
    def initialize(general_purpose_flags = 0)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # A convenience method for creating an Archive::Zip::Codec::Store::Compress
    # object using that class' open method.
    def compressor(io, &b)
      Compress.open(io, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::Store::Decompress object using that class' open
    # method.
    def decompressor(io, &b)
      Decompress.open(io, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Returns an integer which indicates the version of the official ZIP
    # specification which introduced support for this compression codec.
    def version_needed_to_extract
      0x000a
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Returns an integer used to flag that this compression codec is used for a
    # particular ZIP archive entry.
    def compression_method
      ID
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Returns <tt>0</tt> since this compression codec does not make use of
    # general purpose flags of ZIP archive entries.
    def general_purpose_flags
      0
    end
  end
end; end; end
