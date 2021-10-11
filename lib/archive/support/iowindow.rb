# encoding: UTF-8

require 'io/like_helpers/delegated_io'

# IOWindow represents an IO object which wraps another one allowing read access
# to a subset of the data within the stream.
class IOWindow < IO::LikeHelpers::DelegatedIO
  # Creates a new instance of this class using _delegate_ as the data source and
  # where _window_position_ and _window_size_ define the location and size of
  # data window respectively.
  #
  # _delegate_ must be opened for reading and must be seekable.
  # _window_position_ must be an integer greater than or equal to 0.
  # _window_size_ must be an integer greater than or equal to 0.
  def initialize(delegate, window_position, window_size, autoclose: true)
    super(delegate, autoclose: autoclose)

    @window_position = Integer(window_position)
    if @window_position < 0
      raise ArgumentError, 'window_position must be at least 0'
    end
    @window_size = Integer(window_size)
    raise ArgumentError, 'window_size must be at least 0' if @window_size < 0

    @pos = 0
  end

  def read(length, buffer: nil)
    # Error out if the end of the window is reached.
    raise EOFError, 'end of file reached' if @pos >= @window_size

    # Limit the read operation to the window.
    length = @window_size - @pos if @pos + length > @window_size

    # Fill a buffer with the data from the delegate.
    result = delegate.read(length, buffer: buffer)
    return result if Symbol === result

    @pos += buffer.length

    result
  end

  def seek(amount, whence = IO::SEEK_SET)
    # Convert the amount into an absolute position.
    case whence
    when IO::SEEK_SET
      new_pos = amount
    when IO::SEEK_CUR
      new_pos = @pos + amount
    when IO::SEEK_END
      new_pos = @window_size + amount
    end

    # Error out if the position is outside the window.
    if new_pos < 0 || new_pos > @window_size
      raise Errno::EINVAL, 'Invalid argument'
    end

    @pos = super(new_pos + @window_position, IO::SEEK_SET) - @window_position
  end
end
