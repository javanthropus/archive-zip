# encoding: UTF-8

require 'io/like_helpers/io_wrapper'

require 'archive/support/ioextensions'
require 'archive/zip/central_directory_header'
require 'archive/zip/codec/deflate'
require 'archive/zip/codec/null_encryption'
require 'archive/zip/codec/store'
require 'archive/zip/codec/traditional_encryption'
require 'archive/zip/data_descriptor'
require 'archive/zip/dos_time'
require 'archive/zip/entry/abstract_entry'
require 'archive/zip/entry/directory'
require 'archive/zip/entry/file'
require 'archive/zip/entry/symlink'
require 'archive/zip/error'
require 'archive/zip/extra_field'
require 'archive/zip/general_purpose_flags'
require 'archive/zip/local_file_header'

module Archive; class Zip
module Entry
  # Cleans up and returns _zip_path_ by eliminating . and .. references,
  # leading and trailing <tt>/</tt>'s, and runs of <tt>/</tt>'s.
  def self.expand_path(zip_path)
    result = []
    source = zip_path.split('/')

    source.each do |e|
      next if e.empty? || e == '.'

      if e == '..' && ! (result.last.nil? || result.last == '..') then
        result.pop
      else
        result.push(e)
      end
    end
    result.shift while result.first == '..'

    result.join('/')
  end

  # Creates a new Entry based upon a file, symlink, or directory.  _file_path_
  # points to the source item.  _options_ is a Hash optionally containing the
  # following:
  # <b>:zip_path</b>::
  #   The path for the entry in the archive where `/' is the file separator
  #   character.  This defaults to the basename of _file_path_ if unspecified.
  # <b>:follow_symlinks</b>::
  #   When set to +true+ (the default), symlinks are treated as the files or
  #   directories to which they point.
  # <b>:compression_codec</b>::
  #   Specifies a proc, lambda, or class.  If a proc or lambda is used, it
  #   must take a single argument containing a zip entry and return a
  #   compression codec class to be instantiated and used with the entry.
  #   Otherwise, a compression codec class must be specified directly.  When
  #   unset, the default compression codec for each entry type is used.
  # <b>:encryption_codec</b>::
  #   Specifies a proc, lambda, or class.  If a proc or lambda is used, it
  #   must take a single argument containing a zip entry and return an
  #   encryption codec class to be instantiated and used with the entry.
  #   Otherwise, an encryption codec class must be specified directly.  When
  #   unset, the default encryption codec for each entry type is used.
  #
  # Raises Archive::Zip::EntryError if processing the given file path results
  # in a file not found error.
  def self.from_file(file_path, options = {})
    zip_path        = options.has_key?(:zip_path) ?
                      expand_path(options[:zip_path]) :
                      ::File.basename(file_path)
    follow_symlinks = options.has_key?(:follow_symlinks) ?
                      options[:follow_symlinks] :
                      true

    # Avoid repeatedly stat'ing the file by storing the stat structure once.
    begin
      stat = follow_symlinks ?
             ::File.stat(file_path) :
             ::File.lstat(file_path)
    rescue Errno::ENOENT
      if ::File.symlink?(file_path) then
        raise Zip::EntryError,
          "symlink at `#{file_path}' points to a non-existent file `#{::File.readlink(file_path)}'"
      else
        raise Zip::EntryError, "no such file or directory `#{file_path}'"
      end
    end

    # Ensure that zip paths for directories end with '/'.
    if stat.directory? then
      zip_path += '/'
    end

    # Instantiate the entry.
    if stat.symlink? then
      entry = Entry::Symlink.new(zip_path)
      entry.link_target = ::File.readlink(file_path)
    elsif stat.file? then
      entry = Entry::File.new(zip_path)
      entry.file_path = file_path
    elsif stat.directory? then
      entry = Entry::Directory.new(zip_path)
    else
      raise Zip::EntryError,
        "unsupported file type `#{stat.ftype}' for file `#{file_path}'"
    end

    # Set the compression and encryption codecs.
    unless options[:compression_codec].nil? then
      if options[:compression_codec].kind_of?(Proc) then
        entry.compression_codec = options[:compression_codec][entry].new
      else
        entry.compression_codec = options[:compression_codec].new
      end
    end
    unless options[:encryption_codec].nil? then
      if options[:encryption_codec].kind_of?(Proc) then
        entry.encryption_codec = options[:encryption_codec][entry].new
      else
        entry.encryption_codec = options[:encryption_codec].new
      end
    end

    # Set the entry's metadata.
    entry.uid = stat.uid
    entry.gid = stat.gid
    entry.mtime = stat.mtime
    entry.atime = stat.atime
    entry.mode = stat.mode

    entry
  end

  # Creates and returns a new entry object by parsing from the current
  # position of _io_.  _io_ must be a readable, IO-like object which is
  # positioned at the start of a central file record following the signature
  # for that record.
  #
  # <b>NOTE:</b> For now _io_ MUST be seekable.
  #
  # Currently, the only entry objects returned are instances of
  # Archive::Zip::Entry::File, Archive::Zip::Entry::Directory, and
  # Archive::Zip::Entry::Symlink.  Any other kind of entry will be mapped into
  # an instance of Archive::Zip::Entry::File.
  #
  # Raises Archive::Zip::EntryError for any other errors related to processing
  # the entry.
  def self.parse(io)
    # Parse the central file record and then use the information found there
    # to locate and parse the corresponding local file record.
    cfr = CentralDirectoryHeader.parse(io)
    next_record_position = io.pos
    io.seek(cfr.local_header_position)
    unless IOExtensions.read_exactly(io, 4) == LFH_SIGNATURE then
      raise Zip::EntryError, 'bad local file header signature'
    end
    lfr = LocalFileHeader.parse(io, cfr.data_descriptor.compressed_size)

    # Check to ensure that the contents of the central file record and the
    # local file record which are supposed to be duplicated are in fact the
    # same.
    compare_file_records(lfr, cfr)

    begin
      # Load the correct compression codec.
      compression_codec = Codec.create_compression_codec(
        cfr.compression_method,
        cfr.general_purpose_flags
      )
    rescue Zip::Error => e
      raise Zip::EntryError, "`#{cfr.zip_path}': #{e.message}"
    end

    begin
      # Load the correct encryption codec.
      encryption_codec = Codec.create_encryption_codec(
        cfr.general_purpose_flags,
        cfr.extra_fields
      )
    rescue Zip::Error => e
      raise Zip::EntryError, "`#{cfr.zip_path}': #{e.message}"
    end

    # Set up a data descriptor with expected values for later comparison.
    expected_data_descriptor = cfr.data_descriptor.dup

    # Create the entry.
    expanded_path = expand_path(cfr.zip_path)
    io_window = IOWindow.new(
      IO::LikeHelpers::IOWrapper.new(io), io.pos, cfr.data_descriptor.compressed_size
    )
    if cfr.zip_path[-1..-1] == '/' then
      # This is a directory entry.
      entry = Entry::Directory.new(expanded_path, io_window)
    elsif (cfr.external_file_attributes >> 16) & 0770000 == 0120000 then
      # This is a symlink entry.
      entry = Entry::Symlink.new(expanded_path, io_window)
    else
      # Anything else is a file entry.
      entry = Entry::File.new(expanded_path, io_window)
    end

    # Set the expected data descriptor so that extraction can be verified.
    entry.expected_data_descriptor = expected_data_descriptor
    # Record the compression codec.
    entry.compression_codec = compression_codec
    # Record the encryption codec.
    entry.encryption_codec = encryption_codec
    # Set some entry metadata.
    entry.mtime = cfr.mtime
    # Only set mode bits for the entry if the external file attributes are
    # Unix-compatible.
    if cfr.made_by_version & 0xFF00 == 0x0300 then
      entry.mode = cfr.external_file_attributes >> 16
    end
    entry.comment = cfr.comment
    cfr.extra_fields.each { |ef| entry.add_extra_field(ef) }
    lfr.extra_fields.each { |ef| entry.add_extra_field(ef) }

    # Return to the beginning of the next central directory record.
    io.seek(next_record_position)

    entry
  end

  private

  # Compares the local and the central file records found in _lfr_ and _cfr
  # respectively.  Raises Archive::Zip::EntryError if the comparison fails.
  def self.compare_file_records(lfr, cfr)
    # Exclude the extra fields from the comparison since some implementations,
    # such as InfoZip, are known to have differences in the extra fields used
    # in local file records vs. central file records.
    if lfr.zip_path != cfr.zip_path then
      raise Zip::EntryError, "zip path differs between local and central file records: `#{lfr.zip_path}' != `#{cfr.zip_path}'"
    end
    if lfr.extraction_version != cfr.extraction_version then
      raise Zip::EntryError, "`#{cfr.zip_path}': extraction version differs between local and central file records"
    end
    if lfr.data_descriptor.crc32 != cfr.data_descriptor.crc32 then
      raise Zip::EntryError, "`#{cfr.zip_path}': CRC32 differs between local and central file records"
    end
    if lfr.data_descriptor.compressed_size != cfr.data_descriptor.compressed_size then
      raise Zip::EntryError, "`#{cfr.zip_path}': compressed size differs between local and central file records"
    end
    if lfr.data_descriptor.uncompressed_size != cfr.data_descriptor.uncompressed_size then
      raise Zip::EntryError, "`#{cfr.zip_path}': uncompressed size differs between local and central file records"
    end
    if lfr.general_purpose_flags != cfr.general_purpose_flags then
      raise Zip::EntryError, "`#{cfr.zip_path}': general purpose flags differ between local and central file records"
    end
    if lfr.compression_method != cfr.compression_method then
      raise Zip::EntryError, "`#{cfr.zip_path}': compression method differs between local and central file records"
    end
    if lfr.mtime != cfr.mtime then
      raise Zip::EntryError, "`#{cfr.zip_path}': last modified time differs between local and central file records"
    end
  end
end
end; end
