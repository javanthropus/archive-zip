# encoding: UTF-8

require 'io/like_helpers/delegated_io'

require 'archive/support/zlib'
require 'archive/zip/data_descriptor'

module Archive; class Zip; module Codec; class Deflate
# Archive::Zip::Codec::Deflate::Reader extends Zlib::ZReader in order to
# specify the standard Zlib options required by ZIP archives and to provide
# a close method which can optionally close the delegate IO-like object.
# In addition a convenience method is provided for generating DataDescriptor
# objects based on the data which is passed through this object.
#
# Instances of this class should only be accessed via the
# Archive::Zip::Codec::Deflate#decompressor method.
class Reader < IO::LikeHelpers::DelegatedIO
  # The number of bytes to read from the delegate object each time the
  # internal read buffer is filled.
  DEFAULT_DELEGATE_READ_SIZE = 8192

  # Creates a new instance of this class.  _delegate_ must respond to the
  # _read_ method as an IO instance would.
  #
  # In all cases, Zlib::DataError is raised if the wrong stream format is
  # found <b>when reading</b>.
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
  def initialize(
    delegate,
    autoclose: true,
    delegate_read_size: DEFAULT_DELEGATE_READ_SIZE
  )
    super(
      IO === delegate ? IO::Like::IOWrapper.new(delegate) : delegate,
      autoclose: autoclose
    )

    @delegate_read_size = delegate_read_size
    @read_buffer = "\0".b * @delegate_read_size
    @inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    @inflate_buffer = ''
    @inflate_buffer_idx = 0
    @compressed_size = nil
    @uncompressed_size = nil
    @crc32 = 0
  end

  # The number of bytes to read from the delegate object each time the
  # internal read buffer is filled.
  attr_accessor :delegate_read_size

  # Closes the reader.
  #
  # Raises IOError if called more than once.
  def close
    return nil if closed?

    result = super
    return result if Symbol === result

    @compressed_size = @inflater.total_in
    @uncompressed_size = @inflater.total_out
    @inflate_buffer = nil
    @inflate_buffer_idx = 0

    # Avoid warnings by only attempting to close the inflater if it was
    # correctly finished.
    @inflater.close if @inflater.finished?

    nil
  end

  # The CRC32 checksum of the uncompressed data read using this object.
  #
  # <b>NOTE:</b> The contents of the internal read buffer are immediately
  # processed any time the internal buffer is filled, so this checksum is
  # only accurate if all data has been read out of this object.
  attr_reader :crc32

  # Returns the number of bytes sent to be compressed so far.
  #
  # <b>NOTE:</b> This value is updated whenever the internal read buffer needs
  # to be filled, not when data is read out of this stream.
  def compressed_size
    @inflater.closed? ? @compressed_size : @inflater.total_in
  end

  # Returns the number of bytes of decompressed data produced so far.
  #
  # <b>NOTE:</b> This value is updated whenever the internal read buffer needs
  # to be filled, not when data is read out of this stream.
  def uncompressed_size
    @inflater.closed? ? @uncompressed_size : @inflater.total_out
  end

  # Returns an instance of Archive::Zip::DataDescriptor with information
  # regarding the data which has passed through this object from the
  # delegate object.  It is recommended to call the close method before
  # calling this in order to ensure that no further read operations change
  # the state of this object.
  def data_descriptor
    DataDescriptor.new(crc32, compressed_size, uncompressed_size)
  end

  def read(length, buffer: nil, buffer_offset: 0)
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0
    if ! buffer.nil?
      if buffer_offset < 0 || buffer_offset >= buffer.bytesize
        raise ArgumentError, 'buffer_offset is not a valid buffer index'
      end
      if buffer.bytesize - buffer_offset < length
        raise ArgumentError, 'length is greater than available buffer space'
      end
    end

    assert_readable

    if @inflate_buffer_idx >= @inflate_buffer.size
      raise EOFError, 'end of file reached' if @inflater.finished?

      @inflate_buffer =
        begin
          result = super(@delegate_read_size, buffer: @read_buffer)
          return result if Symbol === result
          @inflater.inflate(@read_buffer[0, result])
        rescue EOFError
          @inflater.inflate(nil)
        end
      @inflate_buffer_idx = 0
    end

    available = @inflate_buffer.size - @inflate_buffer_idx
    length = available if available < length
    content = @inflate_buffer[@inflate_buffer_idx, length]
    @inflate_buffer_idx += length
    @crc32 = Zlib.crc32(content, @crc32)
    return content if buffer.nil?

    buffer[buffer_offset, length] = content
    return length
  end

  # Allows resetting this object and the delegate object back to the beginning
  # of the stream or reporting the current position in the stream.
  #
  # Raises Errno::EINVAL unless _offset_ is <tt>0</tt> and _whence_ is either
  # IO::SEEK_SET or IO::SEEK_CUR.  Raises Errno::EINVAL if _whence_ is
  # IO::SEEK_SEK and the delegate object does not respond to the _rewind_
  # method.
  def seek(amount, whence = IO::SEEK_SET)
    assert_open
    raise Errno::ESPIPE if amount != 0 || whence == IO::SEEK_END

    case whence
    when IO::SEEK_SET
      result = super
      return result if Symbol === result
      @inflater.reset
      @inflate_buffer_idx = @inflate_buffer.size
      @crc32 = 0
      result
    when IO::SEEK_CUR
      @inflater.total_out - (@inflate_buffer.size - @inflate_buffer_idx)
    else
      raise Errno::EINVAL
    end
  end
end
end; end; end; end
