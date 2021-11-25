# encoding: UTF-8

require 'archive/zip/codec/store/reader'
require 'archive/zip/codec/store/writer'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::Store is a handle for the store-unstore (no
  # compression) codec.
  class Store
    # The numeric identifier assigned to this compresion codec by the ZIP
    # specification.
    ID = 0

    # Register this compression codec.
    COMPRESSION_CODECS[ID] = self

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # Creates a new instance of this class.  _general_purpose_flags_ is not
    # used.
    def initialize(general_purpose_flags = 0)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # A convenience method for creating an Archive::Zip::Codec::Store::Writer
    # object using that class' open method.
    def compressor(io, &b)
      Writer.open(io, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for compression codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::Store::Reader object using that class' open
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
      0x000a
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
    # Returns <tt>0</tt> since this compression codec does not make use of
    # general purpose flags of ZIP archive entries.
    def general_purpose_flags
      0
    end
  end
end; end; end
