# encoding: UTF-8

require 'io/like_helpers/delegated_io'

require 'archive/support/zlib'
require 'archive/zip/data_descriptor'

module Archive; class Zip; module Codec; class Store
# Archive::Zip::Codec::Store::Writer is simply a writable, IO-like wrapper
# around a writable, IO-like object which provides a CRC32 checksum of the
# data written through it as well as the count of the total amount of data.
# A _close_ method is also provided which can optionally close the delegate
# object.  In addition a convenience method is provided for generating
# DataDescriptor objects based on the data which is passed through this
# object.
#
# Instances of this class should only be accessed via the
# Archive::Zip::Codec::Store#compressor method.
class Writer < IO::LikeHelpers::DelegatedIO
  # Creates a new instance of this class using _io_ as a data sink.  _io_
  # must be writable and must provide a write method as IO does or errors
  # will be raised when performing write operations.
  def initialize(delegate, autoclose: true)
    super(
      IO === delegate ? IO::Like::IOWrapper.new(delegate) : delegate,
      autoclose: autoclose
    )
    @crc32 = 0
    @uncompressed_size = 0
  end

  # Returns an instance of Archive::Zip::DataDescriptor with information
  # regarding the data which has passed through this object to the delegate
  # object.  The close or flush methods should be called before using this
  # method in order to ensure that any possibly buffered data is flushed to
  # the delegate object; otherwise, the contents of the data descriptor may
  # be inaccurate.
  def data_descriptor
    DataDescriptor.new(@crc32, @uncompressed_size, @uncompressed_size)
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

    case whence
    when IO::SEEK_SET
      result = super
      return result if Symbol === result
      @crc32 = 0
      @uncompressed_size = 0
      result
    when IO::SEEK_CUR
      @uncompressed_size
    else
      raise Errno::EINVAL
    end
  end

  # Writes _string_ to the delegate object and returns the number of bytes
  # actually written.  Updates the uncompressed_size and crc32 attributes as
  # a side effect.
  def write(buffer, length: buffer.bytesize)
    result = super
    return result if Symbol === result

    @uncompressed_size += result
    buffer = buffer[0, result] if result < buffer.bytesize
    @crc32 = Zlib.crc32(buffer, @crc32)

    result
  end
end
end; end; end; end
