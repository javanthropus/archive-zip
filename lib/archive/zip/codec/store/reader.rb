# encoding: UTF-8

require 'io/like_helpers/delegated_io'

require 'archive/support/zlib'
require 'archive/zip/data_descriptor'

module Archive; class Zip; module Codec; class Store
# Archive::Zip::Codec::Store::Reader is a readable, IO-like wrapper
# around a readable, IO-like object which provides a CRC32 checksum of the
# data read through it as well as the count of the total amount of data.  A
# _close_ method is also provided which can optionally close the delegate
# object.  In addition a convenience method is provided for generating
# DataDescriptor objects based on the data which is passed through this
# object.
#
# Instances of this class should only be accessed via the
# Archive::Zip::Codec::Store#decompressor method.
class Reader < IO::LikeHelpers::DelegatedIO
  # Creates a new instance of this class using _io_ as a data source.  _io_
  # must be readable and provide a _read_ method as an IO instance would or
  # errors will be raised when performing read operations.
  #
  # This class has extremely limited seek capabilities.  It is possible to
  # seek with an offset of <tt>0</tt> and a whence of <tt>IO::SEEK_CUR</tt>.
  # As a result, the _pos_ and _tell_ methods also work as expected.
  #
  # Due to certain optimizations within IO::Like#seek and if there is data
  # in the read buffer, the _seek_ method can be used to seek forward from
  # the current stream position up to the end of the buffer.  Unless it is
  # known definitively how much data is in the buffer, it is best to avoid
  # relying on this behavior.
  #
  # If _io_ also responds to _rewind_, then the _rewind_ method of this
  # class can be used to reset the whole stream back to the beginning. Using
  # _seek_ of this class to seek directly to offset <tt>0</tt> using
  # <tt>IO::SEEK_SET</tt> for whence will also work in this case.
  #
  # Any other seeking attempts, will raise Errno::EINVAL exceptions.
  def initialize(delegate, autoclose: true)
    super
    @crc32 = 0
    @uncompressed_size = 0
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

  # Returns at most _length_ bytes from the delegate object.  Updates the
  # uncompressed_size and crc32 attributes as a side effect.
  def read(length, buffer: nil, buffer_offset: 0)
    result = super
    return result if Symbol === result

    buffer = result if buffer.nil?
    @uncompressed_size += buffer.bytesize
    @crc32 = Zlib.crc32(buffer, @crc32)

    result
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
end
end; end; end; end
