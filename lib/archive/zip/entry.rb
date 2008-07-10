require 'archive/zip/codec/store'
require 'archive/zip/error'
require 'archive/zip/extrafield'
require 'archive/zip/datadescriptor'

module Archive; class Zip
  # The Archive::Zip::Entry mixin provides classes with methods implementing
  # many of the common features of all entry types.  Some of these methods, such
  # as _dump_local_file_record_ and _dump_central_file_record_, are required by
  # Archive::Zip in order to store the entry into an archive.  Those should be
  # left alone.  Others, such as _ftype_ and <i>mode=</i>, are expected to be
  # overridden to provide sensible information for the new entry type.
  #
  # A class using this mixin must provide 2 methods: _extract_ and
  # _dump_compressed_data_.  _extract_ should be a public method with the
  # following signature:
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
  # _dump_compressed_data_ should be a private method with the following
  # signature:
  #
  #   def dump_compressed_data(io)
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
  module Entry
    CFHRecord = Struct.new(
      :made_by_version,
      :extraction_version,
      :general_purpose_flags,
      :compression_method,
      :mtime,
      :crc32,
      :compressed_size,
      :uncompressed_size,
      :disk_number_start,
      :internal_file_attributes,
      :external_file_attributes,
      :local_header_position,
      :zip_path,
      :extra_fields,
      :comment
    )

    LFHRecord = Struct.new(
      :extraction_version,
      :general_purpose_flags,
      :compression_method,
      :mtime,
      :crc32,
      :compressed_size,
      :uncompressed_size,
      :zip_path,
      :extra_fields,
      :compressed_data
    )

    # When this flag is set in the general purpose flags, it indicates that the
    # read data descriptor record for a local file record is located after the
    # entry's file data.
    FLAG_DATA_DESCRIPTOR_FOLLOWS = 0b1000

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
    # <b>:codec</b>::
    #   When unset, the default codec for file entries is used; otherwise, a
    #   file entry which is created will use the codec set with this option.
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

      if stat.symlink? then
        entry = Entry::Symlink.new(zip_path)
        entry.link_target = ::File.readlink(file_path)
      elsif stat.file? then
        entry = Entry::File.new(zip_path)
        entry.file_path = file_path
        entry.codec = options[:codec] unless options[:codec].nil?
      elsif stat.directory? then
        entry = Entry::Directory.new(zip_path)
      else
        raise Zip::EntryError,
          "unsupported file type `#{stat.ftype}' for file `#{file_path}'"
      end
      entry.uid = stat.uid
      entry.gid = stat.gid
      entry.mtime = stat.mtime
      entry.atime = stat.atime
      entry.mode = stat.mode

      entry
    end

    # Creates and returns a new entry object by parsing from the current
    # position of _io_.  _io_ must be a readable, IO-like object which provides
    # a _readbytes_ method, and it must be positioned at the start of a central
    # file record following the signature for that record.
    #
    # <b>NOTE:</b> For now _io_ MUST be seekable and report such by returning
    # +true+ from its <i>seekable?</i> method.  See IO#seekable?.
    #
    # Currently, the only entry objects returned are instances of
    # Archive::Zip::Entry::File, Archive::Zip::Entry::Directory, and
    # Archive::Zip::Entry::Symlink.  Any other kind of entry will be mapped into
    # an instance of Archive::Zip::Entry::File.
    #
    # Raises Archive::Zip::IOError if _io_ is not seekable.  Raises
    # Archive::Zip::EntryError for any other errors related to processing the
    # entry.
    def self.parse(io)
      # Error out if the IO object is not confirmed seekable.
      unless io.respond_to?(:seekable?) and io.seekable? then
        raise Zip::IOError, 'non-seekable IO object given'
      end

      # Parse the central file record and then use the information found there
      # to locate and parse the corresponding local file record.
      cfr = parse_central_file_record(io)
      next_record_position = io.pos
      io.seek(cfr.local_header_position)
      unless io.readbytes(4) == LFH_SIGNATURE then
        raise Zip::EntryError, 'bad local file header signature'
      end
      lfr = parse_local_file_record(io, cfr.compressed_size)

      # Check to ensure that the contents of the central file record and the
      # local file record which are supposed to be duplicated are in fact the
      # same.
      compare_file_records(lfr, cfr)

      # Raise an error if the codec is not supported.
      unless Codec.supported?(cfr.compression_method) then
        raise Zip::EntryError,
          "`#{cfr.zip_path}': unsupported compression method"
      end

      # Load the correct codec.
      codec = Codec.create(cfr.compression_method, cfr.general_purpose_flags)
      # Set up a data descriptor with expected values for later comparison.
      data_descriptor = DataDescriptor.new(
        cfr.crc32,
        cfr.compressed_size,
        cfr.uncompressed_size
      )
      # Create the entry.
      expanded_path = expand_path(cfr.zip_path)
      if cfr.zip_path[-1..-1] == '/' then
        # This is a directory entry.
        begin
          data_descriptor.verify(DataDescriptor.new(0, 0, 0))
        rescue => e
          raise Zip::EntryError, "`#{cfr.zip_path}': #{e.message}"
        end
        entry = Entry::Directory.new(expanded_path)
      elsif (cfr.external_file_attributes >> 16) & 0770000 == 0120000 then
        # This is a symlink entry.
        entry = Entry::Symlink.new(expanded_path)
        decompressor = codec.decompressor(
          IOWindow.new(io, io.pos, cfr.compressed_size)
        )
        entry.link_target = decompressor.read
        begin
          data_descriptor.verify(decompressor.data_descriptor)
        rescue => e
          raise Zip::EntryError, "`#{cfr.zip_path}': #{e.message}"
        end
        decompressor.close
      else
        # Anything else is a file entry.
        entry = Entry::File.new(expanded_path)
        entry.file_data = codec.decompressor(
          IOWindow.new(io, io.pos, cfr.compressed_size)
        )
        entry.expected_data_descriptor = data_descriptor
      end

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

    # Parses a central file record and returns a CFHRecord instance containing
    # the parsed data.  _io_ must be a readable, IO-like object which provides a
    # _readbytes_ method, and it must be positioned at the start of a central
    # file record following the signature for that record.
    def self.parse_central_file_record(io)
      cfr = CFHRecord.new

      cfr.made_by_version,
      cfr.extraction_version,
      cfr.general_purpose_flags,
      cfr.compression_method,
      dos_mtime,
      cfr.crc32,
      cfr.compressed_size,
      cfr.uncompressed_size,
      file_name_length,
      extra_fields_length,
      comment_length,
      cfr.disk_number_start,
      cfr.internal_file_attributes,
      cfr.external_file_attributes,
      cfr.local_header_position = io.readbytes(42).unpack('vvvvVVVVvvvvvVV')

      cfr.zip_path = io.readbytes(file_name_length)
      cfr.extra_fields = parse_extra_fields(io.readbytes(extra_fields_length))
      cfr.comment = io.readbytes(comment_length)

      # Convert from MSDOS time to Unix time.
      cfr.mtime = DOSTime.new(dos_mtime).to_time

      cfr
    rescue EOFError, TruncatedDataError
      raise Zip::EntryError, 'unexpected end of file'
    end

    # Parses a local file record and returns a LFHRecord instance containing the
    # parsed data.  _io_ must be a readable, IO-like object which provides a
    # readbytes method, and it must be positioned at the start of a local file
    # record following the signature for that record.
    #
    # If the record to be parsed is flagged to have a trailing data descriptor
    # record, _expected_compressed_size_ must be set to an integer counting the
    # number of bytes of compressed data to skip in order to find the trailing
    # data descriptor record, and _io_ must be seekable by providing _pos_ and
    # <i>pos=</i> methods.
    def self.parse_local_file_record(io, expected_compressed_size = nil)
      lfr = LFHRecord.new

      lfr.extraction_version,
      lfr.general_purpose_flags,
      lfr.compression_method,
      dos_mtime,
      lfr.crc32,
      lfr.compressed_size,
      lfr.uncompressed_size,
      file_name_length,
      extra_fields_length = io.readbytes(26).unpack('vvvVVVVvv')

      lfr.zip_path = io.readbytes(file_name_length)
      lfr.extra_fields = parse_extra_fields(io.readbytes(extra_fields_length))

      # Convert from MSDOS time to Unix time.
      lfr.mtime = DOSTime.new(dos_mtime).to_time

      if lfr.general_purpose_flags & FLAG_DATA_DESCRIPTOR_FOLLOWS > 0 then
        saved_pos = io.pos
        io.pos += expected_compressed_size
        # Because the ZIP specification has a history of murkiness, some
        # libraries create trailing data descriptor records with a preceding
        # signature while others do not.
        # This handles both cases.
        possible_signature = io.readbytes(4)
        if possible_signature == DD_SIGNATURE then
          lfr.crc32,
          lfr.compressed_size,
          lfr.uncompressed_size = io.readbytes(12).unpack('VVV')
        else
          lfr.crc32 = possible_signature.unpack('V')[0]
          lfr.compressed_size,
          lfr.uncompressed_size = io.readbytes(8).unpack('VV')
        end
        io.pos = saved_pos
      end

      lfr
    rescue EOFError, TruncatedDataError
      raise Zip::EntryError, 'unexpected end of file'
    end

    # Parses the extra fields for local and central file records and returns an
    # array of extra field objects.  _bytes_ must be a String containing all of
    # the extra field data to be parsed.
    def self.parse_extra_fields(bytes)
      StringIO.open(bytes) do |io|
        extra_fields = []
        while ! io.eof? do
          header_id, data_size = io.readbytes(4).unpack('vv')
          data = io.readbytes(data_size)

          extra_fields << ExtraField.parse(header_id, data)
        end
        extra_fields
      end
    end

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
      if lfr.crc32 != cfr.crc32 then
        raise Zip::EntryError, "`#{cfr.zip_path}': CRC32 differs between local and central file records"
      end
      if lfr.compressed_size != cfr.compressed_size then
        raise Zip::EntryError, "`#{cfr.zip_path}': compressed size differs between local and central file records"
      end
      if lfr.uncompressed_size != cfr.uncompressed_size then
        raise Zip::EntryError, "`#{cfr.zip_path}': uncompressed size differs between local and central file records"
      end
      if lfr.general_purpose_flags != cfr.general_purpose_flags then
        raise Zip::EntryError, "`#{cfr.zip_path}': general purpose flag differs between local and central file records"
      end
      if lfr.compression_method != cfr.compression_method then
        raise Zip::EntryError, "`#{cfr.zip_path}': compression method differs between local and central file records"
      end
      if lfr.mtime != cfr.mtime then
        raise Zip::EntryError, "`#{cfr.zip_path}': last modified time differs between local and central file records"
      end
    end

    public

    # Creates a new, uninitialized Entry instance using the Store compression
    # method.  The zip path is initialized to _zip_path_.
    def initialize(zip_path)
      self.zip_path = zip_path
      self.mtime = Time.now
      self.atime = @mtime
      self.uid = nil
      self.gid = nil
      self.mode = 0777
      self.comment = ''
      self.codec = Zip::Codec::Store.new
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
    # The the file mode/permission bits for this entry.
    attr_accessor :mode
    # The comment associated with this entry.
    attr_accessor :comment
    # The selected compression codec.
    attr_accessor :codec

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

    # Override this method in descendent classes.  It should cause the entry to
    # be extracted from the archive.  This implementation does nothing.
    # _options_ should be a hash used for specifying extraction options, the
    # keys of which should not collide with keys used by Archive::Zip#extract.
    def extract(options = {})
    end

    # Adds _extra_field_ as an extra field specification to this entry.  If
    # _extra_field_ is an instance of
    # Archive::Zip::Entry::ExtraField::ExtendedTimestamp, the values of that
    # field are used to set mtime and atime for this entry.  If _extra_field_ is
    # an instance of Archive::Zip::Entry::ExtraField::Unix, the values of that
    # field are used to set mtime, atime, uid, and gid for this entry.
    def add_extra_field(extra_field)
      @extra_field_data = nil
      @extra_fields << extra_field

      if extra_field.kind_of?(ExtraField::ExtendedTimestamp) then
        self.mtime = extra_field.mtime
        self.atime = extra_field.atime
      elsif extra_field.kind_of?(ExtraField::Unix) then
        self.mtime = extra_field.mtime
        self.atime = extra_field.atime
        self.uid   = extra_field.uid
        self.gid   = extra_field.gid
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
    def dump_local_file_record(io, local_file_record_position)
      @local_file_record_position = local_file_record_position
      bytes_written = 0

      general_purpose_flags = codec.general_purpose_flags
      # Flag that the data descriptor record will follow the compressed file
      # data of this entry unless the IO object can be access randomly.
      general_purpose_flags |= 0b1000 unless io.seekable?

      bytes_written += io.write(LFH_SIGNATURE)
      bytes_written += io.write(
        [
          codec.version_needed_to_extract,
          general_purpose_flags,
          codec.compression_method,
          mtime.to_dos_time.to_i,
          0,
          0,
          0,
          zip_path.length,
          extra_field_data.length
        ].pack('vvvVVVVvv')
      )
      bytes_written += io.write(zip_path)
      bytes_written += io.write(extra_field_data)

      # Get a compressor, write all the file data to it, and get a data
      # descriptor from it.
      codec.compressor(io) do |c|
        dump_compressed_data(c)
        c.close(false)
        @data_descriptor = c.data_descriptor
      end

      bytes_written += @data_descriptor.compressed_size
      if io.seekable? then
        saved_position = io.pos
        io.pos = @local_file_record_position + 14
        @data_descriptor.dump(io)
        io.pos = saved_position
      else
        bytes_written += io.write(DD_SIGNATURE)
        bytes_written += @data_descriptor.dump(io)
      end

      bytes_written
    end

    # Writes the central file record for this entry to _io_, a writable, IO-like
    # object which provides a _write_ method.  Returns the number of bytes
    # written.
    #
    # <b>NOTE:</b> This method should only be called by Archive::Zip.
    def dump_central_file_record(io)
      bytes_written = 0

      general_purpose_flags = codec.general_purpose_flags
      # Flag that the data descriptor record will follow the compressed file
      # data of this entry unless the IO object can be access randomly.
      general_purpose_flags |= FLAG_DATA_DESCRIPTOR_FOLLOWS unless io.seekable?

      bytes_written += io.write(CFH_SIGNATURE)
      bytes_written += io.write(
        [
          version_made_by,
          codec.version_needed_to_extract,
          general_purpose_flags,
          codec.compression_method,
          mtime.to_dos_time.to_i
        ].pack('vvvvV')
      )
      bytes_written += @data_descriptor.dump(io)
      bytes_written += io.write(
        [
          zip_path.length,
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

    def version_made_by
      0x0314
    end

    def extra_field_data
      return @extra_field_data unless @extra_field_data.nil?

      @extra_field_data = @extra_fields.collect do |extra_field|
        unless extra_field.kind_of?(ExtraField::ExtendedTimestamp) ||
               extra_field.kind_of?(ExtraField::Unix) then
          extra_field.dump
        else
          ''
        end
      end.join +
        ExtraField::ExtendedTimestamp.new(mtime, atime, nil).dump +
        ExtraField::Unix.new(mtime, atime, uid, gid).dump
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
end; end

module Archive; class Zip; module Entry
  # Archive::Zip::Entry::Directory represents a directory entry within a Zip
  # archive.
  class Directory
    include Archive::Zip::Entry

    # Inherits the behavior of Archive::Zip::Entry#zip_path= but ensures that
    # there is a trailing slash (<tt>/</tt>) on the end of the path.
    def zip_path=(zip_path)
      super(zip_path)
      @zip_path += '/'
    end

    # Returns the file type of this entry as the symbol <tt>:directory</tt>.
    def ftype
      :directory
    end

    # Returns +true+.
    def directory?
      true
    end

    # Overridden in order to ensure that the proper mode bits are set for a
    # directory.
    def mode=(mode)
      super(040000 | (mode & 07777))
    end

    # Extracts this entry.
    #
    # _options_ is a Hash optionally containing the following:
    # <b>:file_path</b>::
    #   Specifies the path to which this entry will be extracted.  Defaults to
    #   the zip path of this entry.
    # <b>:permissions</b>::
    #   When set to +false+ (the default), POSIX mode/permission bits will be
    #   ignored.  Otherwise, they will be restored if possible.
    # <b>:ownerships</b>::
    #   When set to +false+ (the default), user and group ownerships will be
    #   ignored.  On most systems, only a superuser is able to change
    #   ownerships, so setting this option to +true+ as a regular user may have
    #   no effect.
    # <b>:times</b>::
    #   When set to +false+ (the default), last accessed and last modified times
    #   will be ignored.  Otherwise, they will be restored if possible.
    def extract(options = {})
      # Ensure that unspecified options have default values.
      file_path           = options.has_key?(:file_path) ?
                            options[:file_path].to_s :
                            @zip_path
      restore_permissions = options.has_key?(:permissions) ?
                            options[:permissions] :
                            false
      restore_ownerships  = options.has_key?(:ownerships) ?
                            options[:ownerships] :
                            false
      restore_times       = options.has_key?(:times) ?
                            options[:times] :
                            false

      # Make the directory.
      FileUtils.mkdir_p(file_path)

      # Restore the metadata.
      ::File.chmod(mode, file_path) if restore_permissions
      ::File.chown(uid, gid, file_path) if restore_ownerships
      ::File.utime(atime, mtime, file_path) if restore_times

      nil
    end

    private

    # Directory entries do not have compressed data to write, so do nothing.
    def dump_compressed_data(io)
    end
  end
end; end; end

module Archive; class Zip; module Entry
  # Archive::Zip::Entry::Symlink represents a symlink entry withing a Zip
  # archive.
  class Symlink
    include Archive::Zip::Entry

    # A string indicating the target of a symlink.
    attr_accessor :link_target

    # Returns the file type of this entry as the symbol <tt>:symlink</tt>.
    def ftype
      :symlink
    end

    # Returns +true+.
    def symlink?
      true
    end

    # Overridden in order to ensure that the proper mode bits are set for a
    # symlink.
    def mode=(mode)
      super(0120000 | (mode & 07777))
    end

    # Extracts this entry.
    #
    # _options_ is a Hash optionally containing the following:
    # <b>:file_path</b>::
    #   Specifies the path to which this entry will be extracted.  Defaults to
    #   the zip path of this entry.
    # <b>:permissions</b>::
    #   When set to +false+ (the default), POSIX mode/permission bits will be
    #   ignored.  Otherwise, they will be restored if possible.
    # <b>:ownerships</b>::
    #   When set to +false+ (the default), user and group ownerships will be
    #   ignored.  On most systems, only a superuser is able to change
    #   ownerships, so setting this option to +true+ as a regular user may have
    #   no effect.
    #
    # Raises Archive::Zip::ExtractError if the link_target attribute is not
    # specified.
    def extract(options = {})
      raise Zip::ExtractError, 'link_target is nil' if link_target.nil?

      # Ensure that unspecified options have default values.
      file_path           = options.has_key?(:file_path) ?
                            options[:file_path].to_s :
                            @zip_path
      restore_permissions = options.has_key?(:permissions) ?
                            options[:permissions] :
                            false
      restore_ownerships  = options.has_key?(:ownerships) ?
                            options[:ownerships] :
                            false

      # Create the containing directory tree if necessary.
      parent_dir = ::File.dirname(file_path)
      FileUtils.mkdir_p(parent_dir) unless ::File.exist?(parent_dir)

      # Create the symlink.
      ::File.symlink(link_target, file_path)

      # Restore the metadata.
      # NOTE: Ruby does not have the ability to restore atime and mtime on
      # symlinks at this time (version 1.8.6).
      begin
        ::File.lchmod(mode, file_path) if restore_permissions
      rescue NotImplementedError
        # Ignore on platforms that do not support lchmod.
      end
      begin
        ::File.lchown(uid, gid, file_path) if restore_ownerships
      rescue NotImplementedError
        # Ignore on platforms that do not support lchown.
      end

      nil
    end

    private

    # Write the link target to _io_ as the file data for the entry.
    def dump_compressed_data(io)
      io.write(@link_target)
    end
  end
end; end; end

module Archive; class Zip; module Entry
  # Archive::Zip::Entry::File represents a file entry within a Zip archive.
  class File
    include Archive::Zip::Entry

    # Creates a new file entry where _zip_path_ is the path to the entry in the
    # ZIP archive.  The Archive::Zip::Codec::Deflate codec with the default
    # compression level set (NORMAL) is used by default for compression.
    def initialize(zip_path)
      super(zip_path)
      @file_path = nil
      @file_data = nil
      @expected_data_descriptor = nil
      @codec = Zip::Codec::Deflate.new
    end

    # An Archive::Zip::Entry::DataDescriptor instance which should contain the
    # expected CRC32 checksum, compressed size, and uncompressed size for the
    # file data.  When not +nil+, this is used by #extract to confirm that the
    # data extraction was successful.
    attr_accessor :expected_data_descriptor

    # Returns a readable, IO-like object containing uncompressed file data.  If
    # the file data has not been explicitly set previously, this will return a
    # Archive::Zip::Codec::Store::Unstore instance wrapping either a File
    # instance based on the +file_path+ attribute, if set, or an empty StringIO
    # instance otherwise.
    #
    # <b>NOTE:</b> It is the responsibility of the user of this attribute to
    # ensure that the #close method of the returned IO-like object is called
    # when the object is no longer needed.
    def file_data
      if @file_data.nil? || @file_data.closed? then
        if @file_path.nil? then
          @file_data = StringIO.new
        else
          @file_data = ::File.new(@file_path, 'rb')
        end
        # Ensure that the IO-like object can return CRC32 and data size
        # information so that it's possible to verify extraction later if
        # desired.
        @file_data = Zip::Codec::Store.new.decompressor(@file_data)
      end
      @file_data
    end

    # Sets the +file_data+ attribute of this object to _file_data_.  If
    # _file_data_ is a String, it will be wrapped in a StringIO instance;
    # otherwise, _file_data_ must be a readable, IO-like object.  _file_data_ is
    # then wrapped inside an Archive::Zip::Codec::Store::Unstore instance before
    # finally setting the +file_data+ attribute.
    #
    # <b>NOTE:</b> As a side effect, the +file_path+ attribute for this object
    # will be set to +nil+.
    def file_data=(file_data)
      @file_path = nil
      if file_data.kind_of?(String)
        @file_data = StringIO.new(file_data)
      else
        @file_data = file_data
      end
      # Ensure that the IO-like object can return CRC32 and data size
      # information so that it's possible to verify extraction later if desired.
      unless @file_data.respond_to?(:data_descriptor) then
        @file_data = Zip::Codec::Store.new.decompressor(@file_data)
      end
      @file_data
    end

    # The path to a file whose contents are to be used for uncompressed file
    # data.  This will be +nil+ if the +file_data+ attribute is set directly.
    attr_reader :file_path

    # Sets the +file_path+ attribute to _file_path_ which should be a String
    # usable with File#new to open a file for reading which will provide the
    # IO-like object for the +file_data+ attribute.
    def file_path=(file_path)
      @file_data = nil
      @file_path = file_path
    end

    # Returns the file type of this entry as the symbol <tt>:file</tt>.
    def ftype
      :file
    end

    # Returns +true+.
    def file?
      true
    end

    # Overridden in order to ensure that the proper mode bits are set for a
    # file.
    def mode=(mode)
      super(0100000 | (mode & 07777))
    end

    # Extracts this entry.
    #
    # _options_ is a Hash optionally containing the following:
    # <b>:file_path</b>::
    #   Specifies the path to which this entry will be extracted.  Defaults to
    #   the zip path of this entry.
    # <b>:permissions</b>::
    #   When set to +false+ (the default), POSIX mode/permission bits will be
    #   ignored.  Otherwise, they will be restored if possible.
    # <b>:ownerships</b>::
    #   When set to +false+ (the default), user and group ownerships will be
    #   ignored.  On most systems, only a superuser is able to change
    #   ownerships, so setting this option to +true+ as a regular user may have
    #   no effect.
    # <b>:times</b>::
    #   When set to +false+ (the default), last accessed and last modified times
    #   will be ignored.  Otherwise, they will be restored if possible.
    #
    # Raises Archive::Zip::ExtractError if the extracted file data appears
    # corrupt.
    def extract(options = {})
      # Ensure that unspecified options have default values.
      file_path           = options.has_key?(:file_path) ?
                            options[:file_path].to_s :
                            @zip_path
      restore_permissions = options.has_key?(:permissions) ?
                            options[:permissions] :
                            false
      restore_ownerships  = options.has_key?(:ownerships) ?
                            options[:ownerships] :
                            false
      restore_times       = options.has_key?(:times) ?
                            options[:times] :
                            false

      # Create the containing directory tree if necessary.
      parent_dir = ::File.dirname(file_path)
      FileUtils.mkdir_p(parent_dir) unless ::File.exist?(parent_dir)

      # Dump the file contents.
      ::File.open(file_path, 'wb') do |f|
        while buffer = file_data.read(4096) do
          f.write(buffer)
        end
      end

      # Verify that the extracted data is good.
      begin
        unless expected_data_descriptor.nil? then
          expected_data_descriptor.verify(file_data.data_descriptor)
        end
      rescue => e
        raise Zip::ExtractError, "`#{zip_path}': #{e.message}"
      end

      # Restore the metadata.
      ::File.chmod(mode, file_path) if restore_permissions
      ::File.chown(uid, gid, file_path) if restore_ownerships
      ::File.utime(atime, mtime, file_path) if restore_times

      # Attempt to rewind the file data back to the beginning, but ignore
      # errors.
      begin
        file_data.rewind
      rescue
        # Ignore.
      end

      nil
    end

    private

    # Write the file data to _io_.
    def dump_compressed_data(io)
      while buffer = file_data.read(4096) do io.write(buffer) end

      # Attempt to ensure that the file data will still be in a readable state
      # at the beginning of the data for the next user, but close it if possible
      # in order to conserve resources.
      if file_path.nil? then
        # When the file_path attribute is not set, the file_data method cannot
        # reinitialize the IO object it returns, so attempt to rewind the file
        # data back to the beginning, but ignore errors.
        begin
          file_data.rewind
        rescue
          # Ignore.
        end
      else
        # Since the file_path attribute is set, the file_data method will
        # reinitialize the IO object it returns if we close the object here.
        file_data.close
      end
    end
  end
end; end; end
