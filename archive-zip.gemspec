# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "archive-zip"
  s.version     = "0.5.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jeremy Bopp"]
  s.email       = ["jeremy@bopp.net"]
  s.homepage    = "http://github.com/javanthropus/archive-zip"
  s.summary     = "Simple, extensible, pure Ruby ZIP archive support."
  s.description = <<-EOD
Archive::Zip provides a simple Ruby-esque interface to creating, extracting, and
updating ZIP archives.  This implementation is 100% Ruby and loosely modeled on
the archive creation and extraction capabilities of InfoZip's zip and unzip
tools.
  EOD
  s.rubyforge_project = "archive-zip"

  s.add_dependency("io-like", ">= 0.3.0")

  s.add_development_dependency("rake", ">= 0.9.0")
  s.add_development_dependency("mspec", ">= 1.5.12")

  s.files        = %w(
    CONTRIBUTORS
    GPL
    HACKING
    LEGAL
    LICENSE
    NEWS
    Rakefile
    README
    TODO
    lib/archive/zip/extra_field.rb
    lib/archive/zip/codec.rb
    lib/archive/zip/extra_field/raw.rb
    lib/archive/zip/extra_field/extended_timestamp.rb
    lib/archive/zip/extra_field/unix.rb
    lib/archive/zip/entry.rb
    lib/archive/zip/codec/store.rb
    lib/archive/zip/codec/traditional_encryption.rb
    lib/archive/zip/codec/null_encryption.rb
    lib/archive/zip/codec/deflate.rb
    lib/archive/zip/version.rb
    lib/archive/zip/error.rb
    lib/archive/zip/data_descriptor.rb
    lib/archive/support/ioextensions.rb
    lib/archive/support/integer.rb
    lib/archive/support/time.rb
    lib/archive/support/iowindow.rb
    lib/archive/support/binary_stringio.rb
    lib/archive/support/io-like.rb
    lib/archive/support/zlib.rb
    lib/archive/zip.rb
  )
  s.test_files   = %w(
    default.mspec
    spec_helper.rb
    spec/ioextensions/read_exactly_spec.rb
    spec/zlib/zreader/compressed_size_spec.rb
    spec/zlib/zreader/new_spec.rb
    spec/zlib/zreader/close_spec.rb
    spec/zlib/zreader/uncompressed_size_spec.rb
    spec/zlib/zreader/open_spec.rb
    spec/zlib/zreader/rewind_spec.rb
    spec/zlib/zreader/read_spec.rb
    spec/zlib/zreader/checksum_spec.rb
    spec/zlib/zreader/tell_spec.rb
    spec/zlib/zreader/seek_spec.rb
    spec/zlib/fixtures/classes.rb
    spec/zlib/fixtures/compressed_file_minmem.bin
    spec/zlib/fixtures/compressed_file_gzip.bin
    spec/zlib/fixtures/compressed_file_raw.bin
    spec/zlib/fixtures/compressed_file_minwin.bin
    spec/zlib/fixtures/compressed_file_nocomp.bin
    spec/zlib/fixtures/compressed_file.bin
    spec/zlib/fixtures/compressed_file_huffman.bin
    spec/zlib/fixtures/raw_file.txt
    spec/zlib/zwriter/write_spec.rb
    spec/zlib/zwriter/compressed_size_spec.rb
    spec/zlib/zwriter/new_spec.rb
    spec/zlib/zwriter/close_spec.rb
    spec/zlib/zwriter/uncompressed_size_spec.rb
    spec/zlib/zwriter/open_spec.rb
    spec/zlib/zwriter/rewind_spec.rb
    spec/zlib/zwriter/checksum_spec.rb
    spec/zlib/zwriter/tell_spec.rb
    spec/zlib/zwriter/seek_spec.rb
    spec/binary_stringio/new_spec.rb
    spec/binary_stringio/set_encoding_spec.rb
    spec/archive/zip/codec/store/fixtures/classes.rb
    spec/archive/zip/codec/store/fixtures/raw_file.txt
    spec/archive/zip/codec/store/compress/write_spec.rb
    spec/archive/zip/codec/store/compress/new_spec.rb
    spec/archive/zip/codec/store/compress/close_spec.rb
    spec/archive/zip/codec/store/compress/open_spec.rb
    spec/archive/zip/codec/store/compress/rewind_spec.rb
    spec/archive/zip/codec/store/compress/data_descriptor_spec.rb
    spec/archive/zip/codec/store/compress/tell_spec.rb
    spec/archive/zip/codec/store/compress/seek_spec.rb
    spec/archive/zip/codec/store/decompress/new_spec.rb
    spec/archive/zip/codec/store/decompress/close_spec.rb
    spec/archive/zip/codec/store/decompress/open_spec.rb
    spec/archive/zip/codec/store/decompress/rewind_spec.rb
    spec/archive/zip/codec/store/decompress/read_spec.rb
    spec/archive/zip/codec/store/decompress/data_descriptor_spec.rb
    spec/archive/zip/codec/store/decompress/tell_spec.rb
    spec/archive/zip/codec/store/decompress/seek_spec.rb
    spec/archive/zip/codec/deflate/fixtures/classes.rb
    spec/archive/zip/codec/deflate/fixtures/compressed_file_nocomp.bin
    spec/archive/zip/codec/deflate/fixtures/compressed_file.bin
    spec/archive/zip/codec/deflate/fixtures/raw_file.txt
    spec/archive/zip/codec/deflate/compress/write_spec.rb
    spec/archive/zip/codec/deflate/compress/new_spec.rb
    spec/archive/zip/codec/deflate/compress/close_spec.rb
    spec/archive/zip/codec/deflate/compress/crc32_spec.rb
    spec/archive/zip/codec/deflate/compress/open_spec.rb
    spec/archive/zip/codec/deflate/compress/data_descriptor_spec.rb
    spec/archive/zip/codec/deflate/compress/checksum_spec.rb
    spec/archive/zip/codec/deflate/decompress/new_spec.rb
    spec/archive/zip/codec/deflate/decompress/close_spec.rb
    spec/archive/zip/codec/deflate/decompress/crc32_spec.rb
    spec/archive/zip/codec/deflate/decompress/open_spec.rb
    spec/archive/zip/codec/deflate/decompress/data_descriptor_spec.rb
    spec/archive/zip/codec/deflate/decompress/checksum_spec.rb
    spec/archive/zip/codec/null_encryption/fixtures/classes.rb
    spec/archive/zip/codec/null_encryption/fixtures/raw_file.txt
    spec/archive/zip/codec/null_encryption/encrypt/write_spec.rb
    spec/archive/zip/codec/null_encryption/encrypt/new_spec.rb
    spec/archive/zip/codec/null_encryption/encrypt/close_spec.rb
    spec/archive/zip/codec/null_encryption/encrypt/open_spec.rb
    spec/archive/zip/codec/null_encryption/encrypt/rewind_spec.rb
    spec/archive/zip/codec/null_encryption/encrypt/tell_spec.rb
    spec/archive/zip/codec/null_encryption/encrypt/seek_spec.rb
    spec/archive/zip/codec/null_encryption/decrypt/new_spec.rb
    spec/archive/zip/codec/null_encryption/decrypt/close_spec.rb
    spec/archive/zip/codec/null_encryption/decrypt/open_spec.rb
    spec/archive/zip/codec/null_encryption/decrypt/rewind_spec.rb
    spec/archive/zip/codec/null_encryption/decrypt/read_spec.rb
    spec/archive/zip/codec/null_encryption/decrypt/tell_spec.rb
    spec/archive/zip/codec/null_encryption/decrypt/seek_spec.rb
    spec/archive/zip/codec/traditional_encryption/fixtures/classes.rb
    spec/archive/zip/codec/traditional_encryption/fixtures/encrypted_file.bin
    spec/archive/zip/codec/traditional_encryption/fixtures/raw_file.txt
    spec/archive/zip/codec/traditional_encryption/encrypt/write_spec.rb
    spec/archive/zip/codec/traditional_encryption/encrypt/new_spec.rb
    spec/archive/zip/codec/traditional_encryption/encrypt/close_spec.rb
    spec/archive/zip/codec/traditional_encryption/encrypt/open_spec.rb
    spec/archive/zip/codec/traditional_encryption/encrypt/rewind_spec.rb
    spec/archive/zip/codec/traditional_encryption/encrypt/tell_spec.rb
    spec/archive/zip/codec/traditional_encryption/encrypt/seek_spec.rb
    spec/archive/zip/codec/traditional_encryption/decrypt/new_spec.rb
    spec/archive/zip/codec/traditional_encryption/decrypt/close_spec.rb
    spec/archive/zip/codec/traditional_encryption/decrypt/open_spec.rb
    spec/archive/zip/codec/traditional_encryption/decrypt/rewind_spec.rb
    spec/archive/zip/codec/traditional_encryption/decrypt/read_spec.rb
    spec/archive/zip/codec/traditional_encryption/decrypt/tell_spec.rb
    spec/archive/zip/codec/traditional_encryption/decrypt/seek_spec.rb
  )

  s.require_path = "lib"
end
