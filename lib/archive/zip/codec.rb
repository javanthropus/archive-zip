module Archive; class Zip
  # Archive::Zip::Codec is a factory class for generating codec object instances
  # based on the compression method and general purpose flag fields of ZIP
  # entries.  When adding a new codec, add a mapping in the _CODECS_ constant
  # from the compression method field value reserved for the codec in the ZIP
  # specification to the class implementing the codec.  See the implementations
  # of Archive::Zip::Codec::Deflate and Archive::Zip::Codec::Store for details
  # on implementing custom codecs.
  module Codec
    # A Hash mapping compression methods to codec implementations.  New codecs
    # must add a mapping here when defined in order to be used.
    CODECS = {}

    # Returns a new codec instance based on _compression_method_ and
    # _general_purpose_flags_.
    def self.create(compression_method, general_purpose_flags)
      CODECS[compression_method].new(general_purpose_flags)
    end

    # Returns +true+ if _compression_method_ is mapped to a codec, +false+
    # otherwise.
    def self.supported?(compression_method)
      CODECS.has_key?(compression_method)
    end
  end
end; end

# Load the standard codecs.
require 'archive/zip/codec/deflate'
require 'archive/zip/codec/store'
