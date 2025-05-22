# encoding: UTF-8

require 'archive/zip/codec/traditional_encryption/reader'
require 'archive/zip/codec/traditional_encryption/writer'
require 'archive/zip/general_purpose_flags'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::TraditionalEncryption is a handle for the traditional
  # encryption codec.
  class TraditionalEncryption
    # The last modified time of the entry to be processed.  Set this before
    # calling #encryptor or #decryptor.
    attr_accessor :mtime

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Writer object using that
    # class' open method.
    def encryptor(io, password, &b)
      Writer.open(io, password, mtime, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::TraditionalEncryption::Reader object using that
    # class' open method.
    def decryptor(io, password, &b)
      Reader.open(io, password, mtime, &b)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns an integer which indicates the version of the official ZIP
    # specification which introduced support for this encryption codec.
    def version_needed_to_extract
      0x0014
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns an integer representing the general purpose flags of a ZIP archive
    # entry using this encryption codec.
    def general_purpose_flags
      GeneralPurposeFlags.new(GeneralPurposeFlags::FLAG_ENCRYPTED)
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns the size of the encryption header in bytes.
    def header_size
      12
    end
  end
end; end; end
