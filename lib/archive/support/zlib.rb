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
    def self.open(io, level = Zlib::DEFAULT_COMPRESSION, window_bits = nil, mem_level = nil, strategy = nil)
      zw = new(io, level, window_bits, mem_level, strategy)
      return zw unless block_given?

      begin
        yield(zw)
      ensure
        zw.close unless zw.closed?
      end
    end

    # Creates a new instance of this class.  _io_ must respond to the _write_
    # method as an instance of IO would.  _level_, _window_bits_, _mem_level_,
    # and _strategy_ are all passed directly to Zlib::Deflate.new().  See the
    # documentation of that method for their meanings.
    #
    # <b>NOTE:</b> Due to limitations in Ruby's finalization capabilities, the
    # #close method is _not_ automatically called when this object is garbage
    # collected.  Make sure to call #close when finished with this object.
    def initialize(io, level = Zlib::DEFAULT_COMPRESSION, window_bits = nil, mem_level = nil, strategy = nil)
      @delegate = io
      @deflater = Zlib::Deflate.new(level, window_bits, mem_level, strategy)
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
      super()
      delegate.write(@deflater.finish)
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

    def unbuffered_write(string)
      until @deflate_buffer.empty? do
        @deflate_buffer.slice!(0, delegate.write(@deflate_buffer))
      end
      @deflate_buffer = @deflater.deflate(string)

      begin
        @deflate_buffer.slice!(0, delegate.write(@deflate_buffer))
      rescue Errno::EINTR, Errno::EAGAIN
        # Ignore this because everything is in the deflate buffer and will be
        # attempted again the next time this method is called.
      end
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
    def self.open(io, window_bits = nil)
      zr = new(io, window_bits)
      return zr unless block_given?

      begin
        yield(zr)
      ensure
        zr.close unless zr.closed?
      end
    end

    # Creates a new instance of this class.  _io_ must respond to the _read_
    # method as an IO instance would.  _window_bits_ is passed directly to
    # Zlib::Inflate.new().  See the documentation of that method for its
    # meaning.  If _io_ also responds to _rewind_, then the _rewind_ method of
    # this class can be used to reset the whole stream back to the beginning.
    #
    # <b>NOTE:</b> Due to limitations in Ruby's finalization capabilities, the
    # #close method is _not_ automatically called when this object is garbage
    # collected.  Make sure to call #close when finished with this object.
    def initialize(io, window_bits = nil)
      @delegate = io
      @delegate_read_size = DEFAULT_DELEGATE_READ_SIZE
      @window_bits = window_bits
      @inflater = Zlib::Inflate.new(@window_bits)
      @crc32 = 0
      @decompress_buffer = ''
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
      if @decompress_buffer.empty? && @inflater.finished? then
        raise EOFError, 'end of file reached'
      end

      begin
        while @decompress_buffer.length < length && ! @inflater.finished? do
          @decompress_buffer <<
            @inflater.inflate(delegate.read(@delegate_read_size))
        end
      rescue Errno::EINTR, Errno::EAGAIN
        raise if @decompress_buffer.empty?
      end
      buffer = @decompress_buffer.slice!(0, length)
      @crc32 = Zlib.crc32(buffer, @crc32)
      buffer
    end

    def unbuffered_seek(offset, whence = IO::SEEK_SET)
      unless offset == 0 && whence == IO::SEEK_SET then
        raise Errno::EINVAL, 'Invalid argument'
      end
      unless delegate.respond_to?(:rewind) then
        raise Errno::ESPIPE, 'Illegal seek'
      end
      delegate.rewind
      @inflater.close
      @inflater = Zlib::Inflate.new(@window_bits)
      @crc32 = 0
      @decompress_buffer = ''
    end
  end
end
