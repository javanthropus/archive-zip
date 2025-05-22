# encoding: UTF-8

module Archive; class Zip
  # Archive::Zip::Codec is a factory class for generating codec object instances
  # based on the compression method and general purpose flag fields of ZIP
  # entries.  When adding a new codec, add a mapping in the _CODECS_ constant
  # from the compression method field value reserved for the codec in the ZIP
  # specification to the class implementing the codec.  See the implementations
  # of Archive::Zip::Codec::Deflate and Archive::Zip::Codec::Store for details
  # on implementing custom codecs.
  module Codec
    # A Hash mapping compression methods to compression codec implementations.
    # New compression codecs must add a mapping here when defined in order to be
    # used.
    COMPRESSION_CODECS = {}

    # A Hash mapping encryption methods to encryption codec implementations.
    # New encryption codecs must add a mapping here when defined in order to be
    # used.
    ENCRYPTION_CODECS  = {}

    # Returns a new compression codec instance based on _compression_method_ and
    # _general_purpose_flags_.
    def self.create_compression_codec(compression_method, general_purpose_flags)
      codec = COMPRESSION_CODECS[compression_method]
      raise Zip::Error, 'unsupported compression codec' unless codec
      codec.new(general_purpose_flags)
    end

    # Returns a new encryption codec instance based on _general_purpose_flags_.
    #
    # <b>NOTE:</b> The signature of this method will have to change in order to
    # support the strong encryption codecs.  This is intended to be an internal
    # method anyway, so this fact should not cause major issues for users of
    # this library.
    def self.create_encryption_codec(general_purpose_flags, extra_fields)
      codec = general_purpose_flags.encrypted? ?
        TraditionalEncryption.new :
        NullEncryption.new
      raise Zip::Error, 'unsupported encryption codec' unless codec
      codec
    end
  end
end; end

require 'archive/zip/codec/deflate'
require 'archive/zip/codec/null_encryption'
require 'archive/zip/codec/store'
require 'archive/zip/codec/traditional_encryption'
