# encoding: UTF-8

require 'io/like_helpers/delegated_io'

require 'archive/support/zlib'
require 'archive/zip/data_descriptor'

module Archive; class Zip; module Codec; class Deflate
# Archive::Zip::Codec::Deflate::Writer extends Zlib::ZWriter in order to
# specify the standard Zlib options required by ZIP archives and to provide
# a close method which can optionally close the delegate IO-like object.
# In addition a convenience method is provided for generating DataDescriptor
# objects based on the data which is passed through this object.
#
# Instances of this class should only be accessed via the
# Archive::Zip::Codec::Deflate#compressor method.
class Writer < IO::LikeHelpers::DelegatedIO
  # Creates a new instance of this class.  _delegate_ must respond to the
  # _write_ method as an instance of IO would.  _level_, _mem_level_, and
  # _strategy_ are all passed directly to Zlib::Deflate.new().
  #
  # <b>
  # The following descriptions of _level_, _mem_level_, and _strategy_ are based
  # upon or pulled largely verbatim from descriptions found in zlib.h version
  # 1.2.3 with changes made to account for different parameter names and to
  # improve readability.  Some of the statements concerning default settings or
  # value ranges may not be accurate depending on the version of the zlib
  # library used by a given Ruby interpreter.
  # </b>
  #
  # The _level_ parameter must be +nil+, Zlib::DEFAULT_COMPRESSION, or between
  # <tt>0</tt> and <tt>9</tt>: <tt>1</tt> gives best speed, <tt>9</tt> gives
  # best compression, <tt>0</tt> gives no compression at all (the input data
  # is simply copied a block at a time).  Zlib::DEFAULT_COMPRESSION requests a
  # default compromise between speed and compression (currently equivalent to
  # level <tt>6</tt>).  If unspecified or +nil+, _level_ defaults to
  # Zlib::DEFAULT_COMPRESSION.
  #
  # The _mem_level_ parameter specifies how much memory should be allocated
  # for the internal compression state.  A value of <tt>1</tt> uses minimum
  # memory but is slow and reduces compression ratio; a value of <tt>9</tt>
  # uses maximum memory for optimal speed.  The default value is <tt>8</tt> if
  # unspecified or +nil+.
  #
  # The _strategy_ parameter is used to tune the compression algorithm.  It
  # only affects the compression ratio but not the correctness of the
  # compressed output even if it is not set appropriately.  The default value
  # is Zlib::DEFAULT_STRATEGY if unspecified or +nil+.
  #
  # Use the value Zlib::DEFAULT_STRATEGY for normal data, Zlib::FILTERED for
  # data produced by a filter (or predictor), Zlib::HUFFMAN_ONLY to force
  # Huffman encoding only (no string match), Zlib::RLE to limit match
  # distances to 1 (run-length encoding), or Zlib::FIXED to simplify decoder
  # requirements.
  #
  # The effect of Zlib::FILTERED is to force more Huffman coding and less
  # string matching; it is somewhat intermediate between
  # Zlib::DEFAULT_STRATEGY and Zlib::HUFFMAN_ONLY.  Filtered data consists
  # mostly of small values with a somewhat random distribution.  In this case,
  # the compression algorithm is tuned to compress them better.
  #
  # Zlib::RLE is designed to be almost as fast as Zlib::HUFFMAN_ONLY, but give
  # better compression for PNG image data.
  #
  # Zlib::FIXED prevents the use of dynamic Huffman codes, allowing for a
  # simpler decoder for special applications.
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
  def initialize(
    delegate,
    autoclose: true,
    level: Zlib::DEFAULT_COMPRESSION,
    mem_level: nil,
    strategy: nil
  )
    super(delegate, autoclose: autoclose)

    @deflater = Zlib::Deflate.new(level, -Zlib::MAX_WBITS, mem_level, strategy)
    @deflate_buffer = ''
    @deflate_buffer_idx = 0
    @crc32 = 0
    @compressed_size = nil
    @uncompressed_size = nil
  end

  # Closes the writer by finishing the compressed data and flushing it to the
  # delegate.
  def close
    return nil if closed?

    result = flush
    return result if Symbol === result

    unless @deflater.finished?
      @deflate_buffer = @deflater.finish
      @deflate_buffer_idx = 0
      result = flush
      return result if Symbol === result
    end

    @compressed_size = @deflater.total_out
    @uncompressed_size = @deflater.total_in
    @deflater.close
    super

    nil
  end

  # The CRC32 checksum of the uncompressed data written using this object.
  #
  # <b>NOTE:</b> Anything still in the internal write buffer has not been
  # processed, so calling #flush prior to examining this attribute may be
  # necessary for an accurate computation.
  attr_reader :crc32

  # Returns the number of bytes of compressed data produced so far.
  #
  # <b>NOTE:</b> This value is only updated when both the internal write
  # buffer is flushed and there is enough data to produce a compressed block.
  # It does not necessarily reflect the amount of data written to the
  # delegate until this stream is closed however.  Until then the only
  # guarantee is that the value will be greater than or equal to <tt>0</tt>.
  def compressed_size
    @deflater.closed? ? @compressed_size : @deflater.total_out
  end

  # Returns the number of bytes sent to be compressed so far.
  #
  # <b>NOTE:</b> This value is only updated when the internal write buffer is
  # flushed.
  def uncompressed_size
    @deflater.closed? ? @uncompressed_size : @deflater.total_in
  end

  # Returns an instance of Archive::Zip::DataDescriptor with information
  # regarding the data which has passed through this object to the delegate
  # object.  The close or flush methods should be called before using this
  # method in order to ensure that any possibly buffered data is flushed to
  # the delegate object; otherwise, the contents of the data descriptor may
  # be inaccurate.
  def data_descriptor
    DataDescriptor.new(crc32, compressed_size, uncompressed_size)
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
      delegate.seek(0, IO::SEEK_SET)
      @deflater.reset
      @deflate_buffer = ''
      @deflate_buffer_idx = 0
      @crc32 = 0
      0
    when IO::SEEK_CUR
      @deflater.total_in
    end
  end

  def write(buffer, length: buffer.bytesize)
    # First try to write out the contents of the deflate buffer because if
    # that raises a failure we can let that pass up the call stack without
    # having polluted the deflater instance.
    result = flush
    return result if Symbol === result

    buffer = buffer[0, length] unless length == buffer.bytesize
    @deflate_buffer = @deflater.deflate(buffer)
    @deflate_buffer_idx = 0
    @crc32 = Zlib.crc32(buffer, @crc32)

    length
  end

  private

  def flush
    while @deflate_buffer_idx < @deflate_buffer.bytesize
      result = delegate.write(@deflate_buffer[@deflate_buffer_idx..-1])
      return result if Symbol === result
      @deflate_buffer_idx += result
    end
    nil
  end
end
end; end; end; end
