# encoding: UTF-8

require 'archive/zip/codec'

module Archive; class Zip; module Codec
  # Archive::Zip::Codec::NullEncryption is a handle for an encryption codec
  # which passes data through itself unchanged.
  class NullEncryption
    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::NullEncryption::Encrypt object using that class' open
    # method.
    def encryptor(io, password, &b)
      return io unless block_given?
      b[io]
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # A convenience method for creating an
    # Archive::Zip::Codec::NullEncryption::Decrypt object using that class' open
    # method.
    def decryptor(io, password, &b)
      return io unless block_given?
      b[io]
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
      0b0000000000000000
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for encryption codec objects.
    #
    # Returns the size of the encryption header in bytes.
    def header_size
      0
    end
  end
end; end; end
