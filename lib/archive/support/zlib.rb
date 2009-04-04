require 'zlib'

require 'archive/support/io-like'

module Zlib # :nodoc:
  if ! const_defined?(:MAX_WBITS) then
    MAX_WBITS = Deflate::MAX_WBITS
  end

  # Zlib::ZWriter is a writable, IO-like object (includes IO::Like) which wraps
  # other writable, IO-like objects in order to facilitate writing data to those
  # objects using the deflate method of compression.
  class ZWriter
    include IO::Like

    # Creates a new instance of this class with the given arguments using #new
    # and then passes the instance to the given block.  The #close method is
    # guaranteed to be called after the block completes.
    #
    # Equivalent to #new if no block is given.
    def self.open(delegate, level = Zlib::DEFAULT_COMPRESSION, window_bits = nil, mem_level = nil, strategy = nil)
      zw = new(delegate, level, window_bits, mem_level, strategy)
      return zw unless block_given?

      begin
        yield(zw)
      ensure
        zw.close unless zw.closed?
      end
    end

    # Creates a new instance of this class.  _delegate_ must respond to the
    # _write_ method as an instance of IO would.  _level_, _window_bits_,
    # _mem_level_, and _strategy_ are all passed directly to
    # Zlib::Deflate.new().  See the documentation of that method for their
    # meanings.
    #
    # This class has extremely limited seek capabilities.  It is possible to
    # seek with an offset of <tt>0</tt> and a whence of <tt>IO::SEEK_CUR</tt>.
    # As a result, the _pos_ and _tell_ methods also work as expected.
    #
    # If _delegate_ also responds to _rewind_, then the _rewind_ method of this
    # class can be used to reset the whole stream back to the beginning. Using
    # _seek_ of this class to seek directly to offset <tt>0</tt> using
    # <tt>IO::SEEK_SET</tt> for whence will also work in this case.
    #
    # <b>NOTE:</b> Due to limitations in Ruby's finalization capabilities, the
    # #close method is _not_ automatically called when this object is garbage
    # collected.  Make sure to call #close when finished with this object.
    def initialize(delegate, level = Zlib::DEFAULT_COMPRESSION, window_bits = nil, mem_level = nil, strategy = nil)
      @delegate = delegate
      @level = level
      @window_bits = window_bits
      @mem_level = mem_level
      @strategy = strategy
      @deflater = Zlib::Deflate.new(@level, @window_bits, @mem_level, @strategy)
      @deflate_buffer = ''
      @crc32 = 0
    end

    # The CRC32 checksum of the uncompressed data written using this object.
    #
    # <b>NOTE:</b> Anything still in the internal write buffer has not been
    # processed, so calling #flush prior to examining this attribute may be
    # necessary for an accurate computation.
    attr_reader :crc32

    protected

    # The delegate object to which compressed data is written.
    attr_reader :delegate

    public

    # Closes the writer by finishing the compressed data and flushing it to the
    # delegate.
    #
    # Raises IOError if called more than once.
    def close
      flush()
      @deflate_buffer << @deflater.finish unless @deflater.finished?
      begin
        until @deflate_buffer.empty? do
          @deflate_buffer.slice!(0, delegate.write(@deflate_buffer))
        end
      rescue Errno::EAGAIN, Errno::EINTR
        retry if write_ready?
      end
      @deflater.close
      super()
      nil
    end

    # Returns the number of bytes of compressed data produced so far.
    #
    # <b>NOTE:</b> Anything still in the internal write buffer has not been
    # processed, so calling #flush prior to calling this method may be necessary
    # for an accurate count.
    def compressed_size
      @deflater.total_out
    end

    # Returns the number of bytes sent to be compressed so far.
    #
    # <b>NOTE:</b> Anything still in the internal write buffer has not been
    # processed, so calling #flush prior to calling this method may be necessary
    # for an accurate count.
    def uncompressed_size
      @deflater.total_in
    end

    private

    # Allows resetting this object and the delegate object back to the beginning
    # of the stream or reporting the current position in the stream.
    #
    # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is either
    # IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_ is
    # IO::SEEK_SEK and the delegate object does not respond to the _rewind_
    # method.
    def unbuffered_seek(offset, whence = IO::SEEK_SET)
      unless offset == 0 &&
             ((whence == IO::SEEK_SET && delegate.respond_to?(:rewind)) ||
              whence == IO::SEEK_CUR) then
        raise Errno::EINVAL
      end

      case whence
      when IO::SEEK_SET
        delegate.rewind
        @deflater.finish
        @deflater.close
        @deflater = Zlib::Deflate.new(
          @level, @window_bits, @mem_level, @strategy
        )
        @crc32 = 0
        @deflate_buffer = ''
        0
      when IO::SEEK_CUR
        @deflater.total_in
      end
    end

    def unbuffered_write(string)
      # First try to write out the contents of the deflate buffer because if
      # that raises a failure we can let that pass up the call stack without
      # having polluted the deflater instance.
      until @deflate_buffer.empty? do
        @deflate_buffer.slice!(0, delegate.write(@deflate_buffer))
      end
      # At this point we can deflate the given string into a new buffer and
      # behave as if it was written.
      @deflate_buffer = @deflater.deflate(string)
      @crc32 = Zlib.crc32(string, @crc32)
      string.length
    end
  end

  # Zlib::ZReader is a readable, IO-like object (includes IO::Like) which wraps
  # other readable, IO-like objects in order to facilitate reading data from
  # those objects using the inflate method of decompression.
  class ZReader
    include IO::Like

    # The number of bytes to read from the delegate object each time the
    # internal read buffer is filled.
    DEFAULT_DELEGATE_READ_SIZE = 4096

    # Creates a new instance of this class with the given arguments using #new
    # and then passes the instance to the given block.  The #close method is
    # guaranteed to be called after the block completes.
    #
    # Equivalent to #new if no block is given.
    def self.open(delegate, window_bits = nil)
      zr = new(delegate, window_bits)
      return zr unless block_given?

      begin
        yield(zr)
      ensure
        zr.close unless zr.closed?
      end
    end

    # Creates a new instance of this class.  _delegate_ must respond to the
    # _read_ method as an IO instance would.  _window_bits_ is passed directly
    # to Zlib::Inflate.new().  See the documentation of that method for its
    # meaning.
    #
    # This class has extremely limited seek capabilities.  It is possible to
    # seek with an offset of <tt>0</tt> and a whence of <tt>IO::SEEK_CUR</tt>.
    # As a result, the _pos_ and _tell_ methods also work as expected.
    #
    # Due to certain optimizations within IO::Like#seek and if there is data in
    # the read buffer, the _seek_ method can be used to seek forward from the
    # current stream position up to the end of the buffer.  Unless it is known
    # definitively how much data is in the buffer, it is best to avoid relying
    # on this behavior.
    #
    # If _delegate_ also responds to _rewind_, then the _rewind_ method of this
    # class can be used to reset the whole stream back to the beginning. Using
    # _seek_ of this class to seek directly to offset <tt>0</tt> using
    # <tt>IO::SEEK_SET</tt> for whence will also work in this case.
    #
    # Any other seeking attempts, will raise Errno::EINVAL exceptions.
    #
    # <b>NOTE:</b> Due to limitations in Ruby's finalization capabilities, the
    # #close method is _not_ automatically called when this object is garbage
    # collected.  Make sure to call #close when finished with this object.
    def initialize(delegate, window_bits = nil)
      @delegate = delegate
      @delegate_read_size = DEFAULT_DELEGATE_READ_SIZE
      @window_bits = window_bits
      @inflater = Zlib::Inflate.new(@window_bits)
      @inflate_buffer = ''
      @crc32 = 0
    end

    # The CRC32 checksum of the uncompressed data read using this object.
    #
    # <b>NOTE:</b> The contents of the internal read buffer are immediately
    # processed any time the buffer is filled, so this count is only accurate if
    # all data has been read out of this object.
    attr_reader :crc32

    # The number of bytes to read from the delegate object each time the
    # internal read buffer is filled.
    attr_accessor :delegate_read_size

    protected

    # The delegate object from which compressed data is read.
    attr_reader :delegate

    public

    # Closes the reader.
    #
    # Raises IOError if called more than once.
    def close
      super()
      @inflater.close
      nil
    end

    # Returns the number of bytes sent to be decompressed so far.
    def compressed_size
      @inflater.total_in
    end

    # Returns the number of bytes of decompressed data produced so far.
    def uncompressed_size
      @inflater.total_out
    end

    private

    def unbuffered_read(length)
      if @inflate_buffer.empty? && @inflater.finished? then
        raise EOFError, 'end of file reached'
      end

      begin
        while @inflate_buffer.length < length && ! @inflater.finished? do
          @inflate_buffer <<
            @inflater.inflate(delegate.read(@delegate_read_size))
        end
      rescue Errno::EINTR, Errno::EAGAIN
        raise if @inflate_buffer.empty?
      end
      buffer = @inflate_buffer.slice!(0, length)
      @crc32 = Zlib.crc32(buffer, @crc32)
      buffer
    end

    # Allows resetting this object and the delegate object back to the beginning
    # of the stream or reporting the current position in the stream.
    #
    # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is either
    # IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_ is
    # IO::SEEK_SEK and the delegate object does not respond to the _rewind_
    # method.
    def unbuffered_seek(offset, whence = IO::SEEK_SET)
      unless offset == 0 &&
             ((whence == IO::SEEK_SET && delegate.respond_to?(:rewind)) ||
              whence == IO::SEEK_CUR) then
        raise Errno::EINVAL
      end

      case whence
      when IO::SEEK_SET
        delegate.rewind
        @inflater.close
        @inflater = Zlib::Inflate.new(@window_bits)
        @crc32 = 0
        @inflate_buffer = ''
        0
      when IO::SEEK_CUR
        @inflater.total_out - @inflate_buffer.length
      end
    end
  end
end
