# encoding: UTF-8

module Archive; class Zip; module Entry
# The Archive::Zip::Entry mixin provides classes with methods implementing
# many of the common features of all entry types.  Some of these methods, such
# as _dump_local_file_ and _dump_central_directory_, are required by
# Archive::Zip in order to store the entry into an archive.  Those should be
# left alone.  Others, such as _ftype_ and <i>mode=</i>, are expected to be
# overridden to provide sensible information for the new entry type.
#
# A class using this mixin must provide 2 methods: _extract_ and
# _dump_file_data_.  _extract_ should be a public method with the following
# signature:
#
#   def extract(options = {})
#     ...
#   end
#
# This method should extract the contents of the entry to the filesystem.
# _options_ should be an optional Hash containing a mapping of option names to
# option values.  Please refer to Archive::Zip::Entry::File#extract,
# Archive::Zip::Entry::Symlink#extract, and
# Archive::Zip::Entry::Directory#extract for examples of the options currently
# supported.
#
# _dump_file_data_ should be a private method with the following signature:
#
#   def dump_file_data(io)
#     ...
#   end
#
# This method should use the _write_ method of _io_ to write all file data.
# _io_ will be a writable, IO-like object.
#
# The class methods from_file and parse are factories for creating the 3 kinds
# of concrete entries currently implemented: File, Directory, and Symlink.
# While it is possible to create new archives using custom entry
# implementations, it is not possible to load those same entries from the
# archive since the parse factory method does not know about them.  Patches
# to support new entry types are welcome.
class AbstractEntry
  # Creates a new, uninitialized Entry instance using the Store compression
  # method.  The zip path is initialized to _zip_path_.  _raw_data_, if
  # specified, must be a readable, IO-like object containing possibly
  # compressed/encrypted file data for the entry.  It is intended to be used
  # primarily by the parse class method.
  def initialize(zip_path, raw_data = nil)
    self.zip_path = zip_path
    self.mtime = Time.now
    self.atime = @mtime
    self.uid = nil
    self.gid = nil
    self.mode = 0777
    self.comment = ''
    self.expected_data_descriptor = nil
    self.compression_codec = Zip::Codec::Store.new
    self.encryption_codec = Zip::Codec::NullEncryption.new
    @raw_data = raw_data
    self.password = nil
    @extra_fields = []
  end

  # The path for this entry in the ZIP archive.
  attr_reader :zip_path
  # The last accessed time.
  attr_accessor :atime
  # The last modified time.
  attr_accessor :mtime
  # The user ID of the owner of this entry.
  attr_accessor :uid
  # The group ID of the owner of this entry.
  attr_accessor :gid
  # The file mode/permission bits for this entry.
  attr_accessor :mode
  # The comment associated with this entry.
  attr_accessor :comment
  # An Archive::Zip::DataDescriptor instance which should contain the expected
  # CRC32 checksum, compressed size, and uncompressed size for the file data.
  # When not +nil+, this is used by #extract to confirm that the data
  # extraction was successful.
  attr_accessor :expected_data_descriptor
  # The selected compression codec.
  attr_accessor :compression_codec
  # The selected encryption codec.
  attr_accessor :encryption_codec
  # The password used with the encryption codec to encrypt or decrypt the file
  # data for an entry.
  attr_accessor :password
  # The raw, possibly compressed and/or encrypted file data for an entry.
  attr_accessor :raw_data

  # Sets the path in the archive for this entry to _zip_path_ after passing it
  # through Archive::Zip::Entry.expand_path and ensuring that the result is
  # not empty.
  def zip_path=(zip_path)
    @zip_path = Archive::Zip::Entry.expand_path(zip_path)
    if @zip_path.empty? then
      raise ArgumentError, "zip path expands to empty string"
    end
  end

  # Returns the file type of this entry as the symbol <tt>:unknown</tt>.
  #
  # Override this in concrete subclasses to return an appropriate symbol.
  def ftype
    :unknown
  end

  # Returns false.
  def file?
    false
  end

  # Returns false.
  def symlink?
    false
  end

  # Returns false.
  def directory?
    false
  end

  # Adds _extra_field_ as an extra field specification to *both* the central
  # file record and the local file record of this entry.
  #
  # If _extra_field_ is an instance of
  # Archive::Zip::Entry::ExtraField::ExtendedTimestamp, the values of that
  # field are used to set mtime and atime for this entry.  If _extra_field_ is
  # an instance of Archive::Zip::Entry::ExtraField::Unix, the values of that
  # field are used to set mtime, atime, uid, and gid for this entry.
  def add_extra_field(extra_field)
    # Try to find an extra field with the same header ID already in the list
    # and merge the new one with that if one exists; otherwise, add the new
    # one to the list.
    existing_extra_field = @extra_fields.find do |ef|
      ef.header_id == extra_field.header_id
    end
    if existing_extra_field.nil? then
      @extra_fields << extra_field
    else
      extra_field = existing_extra_field.merge(extra_field)
    end

    # Set some attributes of this entry based on the settings in select types
    # of extra fields.
    if extra_field.kind_of?(ExtraField::ExtendedTimestamp) then
      self.mtime = extra_field.mtime unless extra_field.mtime.nil?
      self.atime = extra_field.atime unless extra_field.atime.nil?
    elsif extra_field.kind_of?(ExtraField::Unix) then
      self.mtime = extra_field.mtime unless extra_field.mtime.nil?
      self.atime = extra_field.atime unless extra_field.atime.nil?
      self.uid   = extra_field.uid unless extra_field.uid.nil?
      self.gid   = extra_field.gid unless extra_field.uid.nil?
    end
    self
  end

  # Writes the local file record for this entry to _io_, a writable, IO-like
  # object which provides a _write_ method.  _local_file_record_position_ is
  # the offset within _io_ at which writing will begin.  This is used so that
  # when writing to a non-seekable IO object it is possible to avoid calling
  # the _pos_ method of _io_.  Returns the number of bytes written.
  #
  # <b>NOTE:</b> This method should only be called by Archive::Zip.
  def dump_local_file(io, local_file_record_position)
    @local_file_record_position = local_file_record_position
    bytes_written = 0

    # Assume that no trailing data descriptor will be necessary.
    need_trailing_data_descriptor = false
    begin
      io.pos
    rescue Errno::ESPIPE
      # A trailing data descriptor is required for non-seekable IO.
      need_trailing_data_descriptor = true
    end
    if encryption_codec.class == Codec::TraditionalEncryption then
      # HACK:
      # According to the ZIP specification, a trailing data descriptor should
      # only be required when writing to non-seekable IO, but InfoZIP *always*
      # does this when using traditional encryption even though it will also
      # write the data descriptor in the usual place if possible.  Failure to
      # emulate InfoZIP in this behavior will prevent InfoZIP compatibility
      # with traditionally encrypted entries.
      need_trailing_data_descriptor = true
      # HACK:
      # The InfoZIP implementation of traditional encryption requires that the
      # the last modified file time be used as part of the encryption header.
      # This is a deviation from the ZIP specification.
      encryption_codec.mtime = mtime
    end

    # Set the general purpose flags.
    general_purpose_flags = compression_codec.general_purpose_flags.dup
    general_purpose_flags.merge(encryption_codec.general_purpose_flags)
    if need_trailing_data_descriptor then
      general_purpose_flags.data_descriptor_follows = true
    end

    # Select the minimum ZIP specification version needed to extract this
    # entry.
    version_needed_to_extract = compression_codec.version_needed_to_extract
    if encryption_codec.version_needed_to_extract > version_needed_to_extract then
      version_needed_to_extract = encryption_codec.version_needed_to_extract
    end

    # Write the data.
    bytes_written += io.write(LFH_SIGNATURE)
    extra_field_data = local_extra_field_data
    bytes_written += io.write([version_needed_to_extract].pack('v'))
    bytes_written += general_purpose_flags.dump(io)
    bytes_written += io.write(
      [
        compression_codec.compression_method,
        DOSTime.new(mtime).to_i,
        0,
        0,
        0,
        zip_path.bytesize,
        extra_field_data.length
      ].pack('vVVVVvv')
    )
    bytes_written += io.write(zip_path)
    bytes_written += io.write(extra_field_data)
    # Flush buffered data here because writing to the compression pipeline
    # next bypasses the buffer.
    io.flush

    # Pipeline a compressor into an encryptor, write all the file data to the
    # compressor, and get a data descriptor from it.
    compression_codec.compressor(
      encryption_codec.encryptor(
        IO::LikeHelpers::IOWrapper.open(io, autoclose: false), password
      )
    ) do |c|
      dump_file_data(c)
      c.close
      @data_descriptor = DataDescriptor.new(
        c.data_descriptor.crc32,
        c.data_descriptor.compressed_size + encryption_codec.header_size,
        c.data_descriptor.uncompressed_size
      )
    end
    bytes_written += @data_descriptor.compressed_size

    # Write the trailing data descriptor if necessary.
    if need_trailing_data_descriptor then
      bytes_written += io.write(DD_SIGNATURE)
      bytes_written += @data_descriptor.dump(io)
    end

    begin
      # Update the data descriptor located before the compressed data for the
      # entry.
      saved_position = io.pos
      io.pos = @local_file_record_position + 14
      @data_descriptor.dump(io)
      io.pos = saved_position
    rescue Errno::ESPIPE
      # Ignore a failed attempt to update the data descriptor.
    end

    bytes_written
  end

  # Writes the central file record for this entry to _io_, a writable, IO-like
  # object which provides a _write_ method.  Returns the number of bytes
  # written.
  #
  # <b>NOTE:</b> This method should only be called by Archive::Zip.
  def dump_central_directory(io)
    bytes_written = 0

    # Assume that no trailing data descriptor will be necessary.
    need_trailing_data_descriptor = false
    begin
      io.pos
    rescue Errno::ESPIPE
      # A trailing data descriptor is required for non-seekable IO.
      need_trailing_data_descriptor = true
    end
    if encryption_codec.class == Codec::TraditionalEncryption then
      # HACK:
      # According to the ZIP specification, a trailing data descriptor should
      # only be required when writing to non-seekable IO , but InfoZIP
      # *always* does this when using traditional encryption even though it
      # will also write the data descriptor in the usual place if possible.
      # Failure to emulate InfoZIP in this behavior will prevent InfoZIP
      # compatibility with traditionally encrypted entries.
      need_trailing_data_descriptor = true
    end

    # Set the general purpose flags.
    general_purpose_flags  = compression_codec.general_purpose_flags.dup
    general_purpose_flags.merge(encryption_codec.general_purpose_flags)
    if need_trailing_data_descriptor then
      general_purpose_flags.data_descriptor_follows = true
    end

    # Select the minimum ZIP specification version needed to extract this
    # entry.
    version_needed_to_extract = compression_codec.version_needed_to_extract
    if encryption_codec.version_needed_to_extract > version_needed_to_extract then
      version_needed_to_extract = encryption_codec.version_needed_to_extract
    end

    # Write the data.
    bytes_written += io.write(CFH_SIGNATURE)
    bytes_written += io.write([version_made_by, version_needed_to_extract].pack('vv'))
    bytes_written += general_purpose_flags.dump(io)
    bytes_written += io.write(
      [
        compression_codec.compression_method,
        DOSTime.new(mtime).to_i
      ].pack('vV')
    )
    bytes_written += @data_descriptor.dump(io)
    extra_field_data = central_extra_field_data
    bytes_written += io.write(
      [
        zip_path.bytesize,
        extra_field_data.length,
        comment.length,
        0,
        internal_file_attributes,
        external_file_attributes,
        @local_file_record_position
      ].pack('vvvvvVV')
    )
    bytes_written += io.write(zip_path)
    bytes_written += io.write(extra_field_data)
    bytes_written += io.write(comment)

    bytes_written
  end

  private

  def dump_file_data(io)
  end

  def version_made_by
    0x0314
  end

  def central_extra_field_data
    @extra_fields.map(&:dump_central).join
  end

  def local_extra_field_data
    @extra_fields.map(&:dump_local).join
  end

  def internal_file_attributes
    0x0000
  end

  def external_file_attributes
    # Put Unix attributes into the high word and DOS attributes into the low
    # word.
    (mode << 16) + (directory? ? 0x10 : 0)
  end
end
end; end; end
