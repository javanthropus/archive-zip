# encoding: UTF-8

require 'archive/support/ioextensions'

module Archive; class Zip
class GeneralPurposeFlags
  # When this flag is set in the general purpose flags, it indicates that the
  # entry's file data is encrypted using the original (weak) algorithm.
  FLAG_ENCRYPTED               = 0b0001

  # When this flag is set in the general purpose flags, it indicates that the
  # read data descriptor record for a local file record is located after the
  # entry's file data.
  FLAG_DATA_DESCRIPTOR_FOLLOWS = 0b1000

  # A bit mask to mask all compression level bits.
  MASK_COMPRESSION_LEVEL = 0b110

  # A bit mask used to denote that Zlib's default compression level should be
  # used.
  NORMAL = 0b000

  # A bit mask used to denote that Zlib's highest/slowest compression level
  # should be used.
  MAXIMUM = 0b010

  # A bit mask used to denote that Zlib's lowest/fastest compression level
  # should be used.
  FAST = 0b100

  # A bit mask used to denote that Zlib should not compress data at all.
  SUPER_FAST = 0b110

  def self.parse(io)
    new(IOExtensions.read_exactly(io, 2).unpack1('v'))
  end

  def initialize(flags = NORMAL)
    @flags = flags
  end

  def ==(other)
    @flags == other.flags
  end

  protected attr_reader :flags

  def encrypted?
    @flags & FLAG_ENCRYPTED > 0
  end

  def encrypted=(encrypted)
    @flags = encrypted ?
      @flags | FLAG_ENCRYPTED :
      @flags & ~FLAG_ENCRYPTED
  end

  def data_descriptor_follows?
    @flags & FLAG_DATA_DESCRIPTOR_FOLLOWS > 0
  end

  def data_descriptor_follows=(data_descriptor_follows)
    @flags = data_descriptor_follows ?
      @flags | FLAG_DATA_DESCRIPTOR_FOLLOWS :
      @flags & ~FLAG_DATA_DESCRIPTOR_FOLLOWS
  end

  def compression_level
    @flags & MASK_COMPRESSION_LEVEL
  end

  def compression_level=(compression_level)
    @flags =
      (@flags & ~MASK_COMPRESSION_LEVEL) |
      (compression_level | MASK_COMPRESSION_LEVEL)
  end

  def dump(io)
    io.write([@flags].pack('v'))
  end

  def merge(other)
    @flags |= other.flags
  end
end
end; end
