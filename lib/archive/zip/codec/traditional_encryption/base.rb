# encoding: UTF-8

require 'io/like_helpers/delegated_io'

require 'archive/support/zlib'

module Archive; class Zip; module Codec; class TraditionalEncryption
# Archive::Zip::Codec::TraditionalEncryption::Base provides some basic
# methods which are shared between
# Archive::Zip::Codec::TraditionalEncryption::Writer and
# Archive::Zip::Codec::TraditionalEncryption::Reader.
#
# Do not use this class directly.
class Base < IO::LikeHelpers::DelegatedIO
  # Creates a new instance of this class.  _delegate must be an IO-like
  # object to be used as a delegate for IO operations.  _password_ should be
  # the encryption key.  _mtime_ must be the last modified time of the entry
  # to be encrypted/decrypted.
  def initialize(delegate, password, mtime, autoclose: true)
    super(delegate, autoclose: autoclose)
    @password = password
    @mtime = mtime

    initialize_keys
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
      initialize_keys
      result
    when IO::SEEK_CUR
      @bytes_processed
    else
      raise Errno::EINVAL
    end
  end

  private

  # Initializes the keys used for encrypting/decrypting data by setting the
  # keys to well known values and then processing them with the password.
  def initialize_keys
    @key0 = 0x12345678
    @key1 = 0x23456789
    @key2 = 0x34567890
    @password.each_char { |char| update_keys(char) }

    @bytes_processed = 0
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
    @key0 = ~Zlib.crc32(char, ~@key0)
    @key1 = ((@key1 + (@key0 & 0xff)) * 134775813 + 1) & 0xffffffff
    @key2 = ~Zlib.crc32((@key1 >> 24).chr, ~@key2)
    nil
  end

  # Returns the next decryption byte based on the current keys.
  def decrypt_byte
    temp = (@key2 | 2) & 0x0000ffff
    ((temp * (temp ^ 1)) >> 8) & 0x000000ff
  end
end
end; end; end; end
