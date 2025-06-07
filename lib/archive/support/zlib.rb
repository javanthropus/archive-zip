# encoding: UTF-8

require 'zlib'

module Zlib # :nodoc:
  # The maximum size of the zlib history buffer.  Note that zlib allows larger
  # values to enable different inflate modes.  See Zlib::Inflate.new for details.
  # Provided here only for Ruby versions that do not provide it.
  MAX_WBITS = Deflate::MAX_WBITS unless const_defined?(:MAX_WBITS)

  # A deflate strategy which limits match distances to 1, also known as
  # run-length encoding.  Provided here only for Ruby versions that do not
  # provide it.
  RLE = 3 unless const_defined?(:RLE)

  # A deflate strategy which does not use dynamic Huffman codes, allowing for a
  # simpler decoder to be used to inflate.  Provided here only for Ruby versions
  # that do not provide it.
  FIXED = 4 unless const_defined?(:FIXED)
end
