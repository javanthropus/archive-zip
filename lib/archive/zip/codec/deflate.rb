# encoding: UTF-8

require 'archive/zip/codec'
require 'archive/zip/codec/deflate/reader'
require 'archive/zip/codec/deflate/writer'

module Archive; class Zip; module Codec
# Archive::Zip::Codec::Deflate is a handle for the deflate-inflate codec
# as defined in Zlib which provides convenient interfaces for writing and
# reading deflated streams.
class Deflate
  # The numeric identifier assigned to this compression codec by the ZIP
  # specification.
  ID = 8

  # Register this compression codec.
  COMPRESSION_CODECS[ID] = self

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

  # This method signature is part of the interface contract expected by
  # Archive::Zip::Entry for compression codec objects.
  #
  # Creates a new instance of this class using bits 1 and 2 of
  # _general_purpose_flags_ to select a compression level to be used by
  # #compressor to set up a compression IO object.  The constants NORMAL,
  # MAXIMUM, FAST, and SUPER_FAST can be used for _general_purpose_flags_ to
  # manually set the compression level.
  def initialize(general_purpose_flags = NORMAL)
    @compression_level = general_purpose_flags & 0b110
    @zlib_compression_level = case @compression_level
                              when NORMAL
                                Zlib::DEFAULT_COMPRESSION
                              when MAXIMUM
                                Zlib::BEST_COMPRESSION
                              when FAST
                                Zlib::BEST_SPEED
                              when SUPER_FAST
                                Zlib::NO_COMPRESSION
                              else
                                raise Error, 'Invalid compression level'
                              end
  end

  # This method signature is part of the interface contract expected by
  # Archive::Zip::Entry for compression codec objects.
  #
  # A convenience method for creating an
  # Archive::Zip::Codec::Deflate::Writer object using that class' open
  # method.  The compression level for the open method is pulled from the
  # value of the _general_purpose_flags_ argument of new.
  def compressor(io, &b)
    Writer.open(io, level: @zlib_compression_level, &b)
  end

  # This method signature is part of the interface contract expected by
  # Archive::Zip::Entry for compression codec objects.
  #
  # A convenience method for creating an
  # Archive::Zip::Codec::Deflate::Reader object using that class' open
  # method.
  def decompressor(io, &b)
    Reader.open(io, &b)
  end

  # This method signature is part of the interface contract expected by
  # Archive::Zip::Entry for compression codec objects.
  #
  # Returns an integer which indicates the version of the official ZIP
  # specification which introduced support for this compression codec.
  def version_needed_to_extract
    0x0014
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
  # Returns an integer representing the general purpose flags of a ZIP archive
  # entry where bits 1 and 2 are set according to the compression level
  # selected for this object.  All other bits are zero'd out.
  def general_purpose_flags
    @compression_level
  end
end
end; end; end
