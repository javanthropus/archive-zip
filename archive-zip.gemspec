# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'archive-zip'
  s.version     = '0.13.0.pre1'
  s.licenses    = ['MIT']
  s.platform    = Gem::Platform::RUBY
  s.authors     = [
    'Jeremy Bopp',
    'Akira Matsuda',
    'Tatsuya Sato',
    'Kouhei Sutou'
  ]
  s.email       = [
    'jeremy@bopp.net',
    'ronnie@dio.jp',
    'tatsuya.b.sato@rakuten.com',
    'kou@clear-code.com'
  ]
  s.homepage    = 'http://github.com/javanthropus/archive-zip'
  s.summary     = 'Simple, extensible, pure Ruby ZIP archive support.'
  s.description = <<-EOD
Archive::Zip provides a simple Ruby-esque interface to creating, extracting, and
updating ZIP archives.  This implementation is 100% Ruby and loosely modeled on
the archive creation and extraction capabilities of InfoZip's zip and unzip
tools.
  EOD

  s.required_ruby_version = '>= 2.7.0'

  s.add_dependency('io-like', '~> 0.4.0.pre1')

  s.add_development_dependency('rake', '~> 13.0')
  s.add_development_dependency('minitest', '~> 5.11')
  s.add_development_dependency('yard', '~> 0.9')
  s.add_development_dependency('github-markup', '~> 3.0')
  s.add_development_dependency('redcarpet', '~> 3.4')
  s.add_development_dependency('simplecov', '~> 0.20.0')

  s.files        = %w(
    LICENSE
    NEWS.md
    README.md
    lib/archive/support/ioextensions.rb
    lib/archive/support/iowindow.rb
    lib/archive/support/stringio.rb
    lib/archive/support/zlib.rb
    lib/archive/zip.rb
    lib/archive/zip/codec.rb
    lib/archive/zip/codec/deflate.rb
    lib/archive/zip/codec/deflate/reader.rb
    lib/archive/zip/codec/deflate/writer.rb
    lib/archive/zip/codec/null_encryption.rb
    lib/archive/zip/codec/store.rb
    lib/archive/zip/codec/store/reader.rb
    lib/archive/zip/codec/store/writer.rb
    lib/archive/zip/codec/traditional_encryption.rb
    lib/archive/zip/codec/traditional_encryption/base.rb
    lib/archive/zip/codec/traditional_encryption/reader.rb
    lib/archive/zip/codec/traditional_encryption/writer.rb
    lib/archive/zip/data_descriptor.rb
    lib/archive/zip/dos_time.rb
    lib/archive/zip/entry.rb
    lib/archive/zip/error.rb
    lib/archive/zip/extra_field.rb
    lib/archive/zip/extra_field/extended_timestamp.rb
    lib/archive/zip/extra_field/raw.rb
    lib/archive/zip/extra_field/unix.rb
  )
end
