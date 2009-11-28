#!/usr/bin/env ruby

require 'fileutils'
require 'set'
require 'tempfile'

require 'archive/support/io'
require 'archive/support/iowindow'
require 'archive/support/stringio'
require 'archive/support/time'
require 'archive/support/zlib'
require 'archive/zip/codec'
require 'archive/zip/entry'
require 'archive/zip/error'

module Archive # :nodoc:
  # Archive::Zip represents a ZIP archive compatible with InfoZip tools and the
  # archives they generate.  It currently supports both stored and deflated ZIP
  # entries, directory entries, file entries, and symlink entries.  File and
  # directory accessed and modified times, POSIX permissions, and ownerships can
  # be archived and restored as well depending on platform support for such
  # metadata.  Traditional (weak) encryption is also supported.
  #
  # Zip64, digital signatures, and strong encryption are not supported.  ZIP
  # archives can only be read from seekable kinds of IO, such as files; reading
  # archives from pipes or any other non-seekable kind of IO is not supported.
  # However, writing to such IO objects <b><em>IS</em></b> supported.
  class Zip
    include Enumerable

    # The lead-in marker for the end of central directory record.
    EOCD_SIGNATURE     = "PK\x5\x6" # 0x06054b50
    # The lead-in marker for the digital signature record.
    DS_SIGNATURE       = "PK\x5\x5" # 0x05054b50
    # The lead-in marker for the ZIP64 end of central directory record.
    Z64EOCD_SIGNATURE  = "PK\x6\x6" # 0x06064b50
    # The lead-in marker for the ZIP64 end of central directory locator record.
    Z64EOCDL_SIGNATURE = "PK\x6\x7" # 0x07064b50
    # The lead-in marker for a central file record.
    CFH_SIGNATURE      = "PK\x1\x2" # 0x02014b50
    # The lead-in marker for a local file record.
    LFH_SIGNATURE      = "PK\x3\x4" # 0x04034b50
    # The lead-in marker for data descriptor record.
    DD_SIGNATURE       = "PK\x7\x8" # 0x08074b50


    # Creates or possibly updates an archive using _paths_ for new contents.
    #
    # If _archive_ is a String, it is treated as a file path which will receive
    # the archive contents.  If the file already exists, it is assumed to be an
    # archive and will be updated "in place".  Otherwise, a new archive
    # is created.  The archive will be closed once written.
    #
    # If _archive_ has any other kind of value, it is treated as a writable
    # IO-like object which will be left open after the completion of this
    # method.
    #
    # See the instance method #archive for more information about _paths_ and
    # _options_.
    def self.archive(archive, paths, options = {})
      if archive.kind_of?(String) && File.exist?(archive) then
        # Update the archive "in place".
        tmp_archive_path = nil
        File.open(archive) do |archive_in|
          Tempfile.open(*File.split(archive_in.path).reverse) do |archive_out|
            # Save off the path so that the temporary file can be renamed to the
            # archive file later.
            tmp_archive_path = archive_out.path
            # Ensure the file is in binary mode for Windows.
            archive_out.binmode
            # Update the archive.
            open(archive_in, archive_out) { |z| z.archive(paths, options) }
          end
        end
        # Set more reasonable permissions than those set by Tempfile.
        File.chmod(0666 & ~File.umask, tmp_archive_path)
        # Replace the input archive with the output archive.
        File.rename(tmp_archive_path, archive)
      else
        open(nil, archive) { |z| z.archive(paths, options) }
      end
    end

    # Extracts the entries from an archive to _destination_.
    #
    # If _archive_ is a String, it is treated as a file path pointing to an
    # existing archive file.  Otherwise, it is treated as a seekable and
    # readable IO-like object.
    #
    # See the instance method #extract for more information about _destination_
    # and _options_.
    def self.extract(archive, destination, options = {})
      open(archive) { |z| z.extract(destination, options) }
    end

    # Calls #new with the given arguments and yields the resulting Zip instance
    # to the given block.  Returns the result of the block and ensures that the
    # Zip instance is closed.
    #
    # This is a synonym for #new if no block is given.
    def self.open(archive_in, archive_out = nil)
      zf = new(archive_in, archive_out)
      return zf unless block_given?

      begin
        yield(zf)
      ensure
        zf.close unless zf.closed?
      end
    end

    # Opens an existing archive and/or creates a new archive.  At least one of
    # either _archive_in_ or _archive_out_ must be specified and not +nil+;
    # otherwise an ArgumentError will be raised.
    #
    # If _archive_in_ is +nil+, a new, empty archive will be created.  If
    # _archive_in_ is specified and not +nil+, it is used as an existing archive
    # and parsed.  When the value is a String, it is treated as a file path
    # pointing to a readable file; otherwise, it is assumed to be a seekable and
    # readable IO-like object.
    #
    # If _archive_out_ is +nil+, changes made to the archive will be silently
    # discarded.  If _archive_out_ is specified and not +nil+, it is used as a
    # destination to which archive contents will be dumped if modified.  When
    # the value is a String, it is treated as a file path; otherwise, it is
    # assumed to be a writable IO-like object.
    #
    # <b>NOTE:</b> Do <b>NOT</b> try to set _archive_in_ and _archive_out_ such
    # that they both point to the same stream or file at the same time or
    # archive corruption will result.
    #
    # <b>NOTE:</b> The #close method must be called in order to save any
    # modifications to the archive.  Due to limitations in the Ruby finalization
    # capabilities, the #close method is _not_ automatically called when this
    # object is garbage collected.  Make sure to call #close when finished with
    # this object.
    def initialize(archive_in, archive_out = nil)
      if (archive_in.nil? ||
          archive_in.kind_of?(String) && archive_in.empty?) &&
         (archive_out.nil? ||
          archive_out.kind_of?(String) && archive_out.empty?) then
        raise ArgumentError, 'No valid source or destination archive specified'
      end

      @archive_in = archive_in
      @archive_out = archive_out
      @entries = {}
      @dirty = false
      @comment = ''
      @closed = false

      unless @archive_in.nil? then
        if @archive_in.kind_of?(String) then
          @archive_in = File.new(@archive_in, 'rb')
        end
        parse(@archive_in)
      end
    end

    # A comment string for the ZIP archive.
    attr_reader :comment

    # Sets the comment string for the archive and flags the archive as modified.
    def comment=(comment)
      @dirty = true
      @comment = comment
    end

    # Closes the archive.  It is at this point that any changes made to the
    # archive will be persisted to an output stream, assuming an output stream
    # was set in the constructor.
    #
    # The input stream specified by or derived from the _archive_in_ parameter
    # to #new is _always_ closed here.  It is left open until this method is
    # called.  If the _archive_out_ parameter to #new was a String, the output
    # stream will be closed, but it will be left open otherwise.
    #
    # Raises Archive::Zip::IOError if called more than once.
    def close
      raise IOError, 'closed archive' if closed?

      if @dirty && ! @archive_out.nil? then
        # Write the new archive contents if they have been updated and an output
        # archive has been specified.
        if @archive_out.kind_of?(String) then
          # Open a new archive file to receive the data.
          File.open(@archive_out, 'wb') do |archive_out|
            dump(archive_out)
          end
        else
          # Assume the given object is an IO-like object and dump the archive
          # contents to it.
          # Note that we do NOT close @archive_out in this case so that the user
          # may do so at his/her discretion.
          dump(@archive_out)
        end
      end

      @archive_in.close unless @archive_in.nil?
      @closed = true
      nil
    end

    # Returns +true+ if the ZIP archive is closed, +false+ otherwise.
    def closed?
      @closed
    end

    # When the ZIP archive is open, this method iterates through each entry in
    # turn yielding each one to the given block.  Since Zip includes Enumerable,
    # Zip instances are enumerables of Entry instances.
    #
    # Raises Archive::Zip::IOError if called after #close.
    def each(&b)
      raise IOError, 'closed archive' if @closed

      @entries.each_value(&b)
    end

    # Add _entry_ into the ZIP archive replacing any existing entry with the
    # same zip path.
    #
    # Raises Archive::Zip::IOError if called after #close.
    def add_entry(entry)
      raise IOError, 'closed archive' if @closed
      unless entry.kind_of?(Entry) then
        raise ArgumentError, 'Archive::Zip::Entry instance required'
      end

      @entries[entry.zip_path] = entry
      @dirty = true
      self
    end
    alias :<< :add_entry

    # Look up an entry based on the zip path located in _zip_path_.  Returns
    # +nil+ if no entry is found.
    def get_entry(zip_path)
      @entries[zip_path]
    end
    alias :[] :get_entry

    # Removes an entry from the ZIP file and returns the entry or +nil+ if no
    # entry was found to remove.  If _entry_ is an instance of
    # Archive::Zip::Entry, the zip_path attribute is used to find the entry to
    # remove; otherwise, _entry_ is assumed to be a zip path matching an entry
    # in the ZIP archive.
    #
    # Raises Archive::Zip::IOError if called after #close.
    def remove_entry(entry)
      raise IOError, 'closed archive' if @closed

      zip_path = entry
      zip_path = entry.zip_path if entry.kind_of?(Entry)
      entry = @entries.delete(zip_path)
      entry = entry[1] unless entry.nil?
      @dirty ||= ! entry.nil?
      entry
    end

    # Adds _paths_ to the archive.  _paths_ may be either a single path or an
    # Array of paths.  The files and directories referenced by _paths_ are added
    # using their respective basenames as their zip paths.  The exception to
    # this is when the basename for a path is either <tt>"."</tt> or
    # <tt>".."</tt>.  In this case, the path is replaced with the paths to the
    # contents of the directory it references.
    #
    # _options_ is a Hash optionally containing the following:
    # <b>:path_prefix</b>::
    #   Specifies a prefix to be added to the zip_path attribute of each entry
    #   where `/' is the file separator character.  This defaults to the empty
    #   string.  All values are passed through Archive::Zip::Entry.expand_path
    #   before use.
    # <b>:recursion</b>::
    #   When set to +true+ (the default), the contents of directories are
    #   recursively added to the archive.
    # <b>:directories</b>::
    #   When set to +true+ (the default), entries are added to the archive for
    #   directories.  Otherwise, the entries for directories will not be added;
    #   however, the contents of the directories will still be considered if the
    #   <b>:recursion</b> option is +true+.
    # <b>:symlinks</b>::
    #   When set to +false+ (the default), entries for symlinks are excluded
    #   from the archive.  Otherwise, they are included.  <b>NOTE:</b> Unless
    #   <b>:follow_symlinks</b> is explicitly set, it will be set to the logical
    #   NOT of this option in calls to Archive::Zip::Entry.from_file.  If
    #   symlinks should be completely ignored, set both this option and
    #   <b>:follow_symlinks</b> to +false+.  See Archive::Zip::Entry.from_file
    #   for details regarding <b>:follow_symlinks</b>.
    # <b>:flatten</b>::
    #   When set to +false+ (the default), the directory paths containing
    #   archived files will be included in the zip paths of entries representing
    #   the files.  When set to +true+, files are archived without any
    #   containing directory structure in the zip paths.  Setting to +true+
    #   implies that <b>:directories</b> is +false+ and <b>:path_prefix</b> is
    #   empty.
    # <b>:exclude</b>::
    #   Specifies a proc or lambda which takes a single argument containing a
    #   prospective zip entry and returns +true+ if the entry should be excluded
    #   from the archive and +false+ if it should be included.  <b>NOTE:</b> If
    #   a directory is excluded in this way, the <b>:recursion</b> option has no
    #   effect for it.
    # <b>:password</b>::
    #   Specifies a proc, lambda, or a String.  If a proc or lambda is used, it
    #   must take a single argument containing a zip entry and return a String
    #   to be used as an encryption key for the entry.  If a String is used, it
    #   will be used as an encryption key for all encrypted entries.
    # <b>:on_error</b>::
    #   Specifies a proc or lambda which is called when an exception is raised
    #   during the archival of an entry.  It takes two arguments, a file path
    #   and an exception object generated while attempting to archive the entry.
    #   If <tt>:retry</tt> is returned, archival of the entry is attempted
    #   again.  If <tt>:skip</tt> is returned, the entry is skipped.  Otherwise,
    #   the exception is raised.
    # Any other options which are supported by Archive::Zip::Entry.from_file are
    # also supported.
    #
    # Raises Archive::Zip::IOError if called after #close.  Raises
    # Archive::Zip::EntryError if the <b>:on_error</b> option is either unset or
    # indicates that the error should be raised and
    # Archive::Zip::Entry.from_file raises an error.
    #
    # == Example
    #
    # A directory contains:
    #   zip-test
    #   +- dir1
    #   |  +- file2.txt
    #   +- dir2
    #   +- file1.txt
    #
    # Create some archives:
    #   Archive::Zip.open('zip-test1.zip') do |z|
    #     z.archive('zip-test')
    #   end
    #
    #   Archive::Zip.open('zip-test2.zip') do |z|
    #     z.archive('zip-test/.', :path_prefix => 'a/b/c/d')
    #   end
    #
    #   Archive::Zip.open('zip-test3.zip') do |z|
    #     z.archive('zip-test', :directories => false)
    #   end
    #
    #   Archive::Zip.open('zip-test4.zip') do |z|
    #     z.archive('zip-test', :exclude => lambda { |e| e.file? })
    #   end
    #
    # The archives contain:
    #   zip-test1.zip -> zip-test/
    #                    zip-test/dir1/
    #                    zip-test/dir1/file2.txt
    #                    zip-test/dir2/
    #                    zip-test/file1.txt
    #
    #   zip-test2.zip -> a/b/c/d/dir1/
    #                    a/b/c/d/dir1/file2.txt
    #                    a/b/c/d/dir2/
    #                    a/b/c/d/file1.txt
    #
    #   zip-test3.zip -> zip-test/dir1/file2.txt
    #                    zip-test/file1.txt
    #
    #   zip-test4.zip -> zip-test/
    #                    zip-test/dir1/
    #                    zip-test/dir2/
    def archive(paths, options = {})
      raise IOError, 'closed archive' if @closed

      # Ensure that paths is an enumerable.
      paths = [paths] unless paths.kind_of?(Enumerable)
      # If the basename of a path is '.' or '..', replace the path with the
      # paths of all the entries contained within the directory referenced by
      # the original path.
      paths = paths.collect do |path|
        basename = File.basename(path)
        if basename == '.' || basename == '..' then
          Dir.entries(path).reject do |e|
            e == '.' || e == '..'
          end.collect do |e|
            File.join(path, e)
          end
        else
          path
        end
      end.flatten.uniq

      # Ensure that unspecified options have default values.
      options[:path_prefix]  = ''    unless options.has_key?(:path_prefix)
      options[:recursion]    = true  unless options.has_key?(:recursion)
      options[:directories]  = true  unless options.has_key?(:directories)
      options[:symlinks]     = false unless options.has_key?(:symlinks)
      options[:flatten]      = false unless options.has_key?(:flatten)

      # Flattening the directory structure implies that directories are skipped
      # and that the path prefix should be ignored.
      if options[:flatten] then
        options[:path_prefix] = ''
        options[:directories] = false
      end

      # Clean up the path prefix.
      options[:path_prefix] = Entry.expand_path(options[:path_prefix].to_s)

      paths.each do |path|
        # Generate the zip path.
        zip_entry_path = File.basename(path)
        zip_entry_path += '/' if File.directory?(path)
        unless options[:path_prefix].empty? then
          zip_entry_path = "#{options[:path_prefix]}/#{zip_entry_path}"
        end

        begin
          # Create the entry, but do not add it to the archive yet.
          zip_entry = Zip::Entry.from_file(
            path,
            options.merge(
              :zip_path        => zip_entry_path,
              :follow_symlinks => options.has_key?(:follow_symlinks) ?
                                  options[:follow_symlinks] :
                                  ! options[:symlinks]
            )
          )
        rescue StandardError => error
          unless options[:on_error].nil? then
            case options[:on_error][path, error]
            when :retry
              retry
            when :skip
              next
            else
              raise
            end
          else
            raise
          end
        end

        # Skip this entry if so directed.
        if (zip_entry.symlink? && ! options[:symlinks]) ||
           (! options[:exclude].nil? && options[:exclude][zip_entry]) then
          next
        end

        # Set the encryption key for the entry.
        if options[:password].kind_of?(String) then
          zip_entry.password = options[:password]
        elsif ! options[:password].nil? then
          zip_entry.password = options[:password][zip_entry]
        end

        # Add entries for directories (if requested) and files/symlinks.
        if (! zip_entry.directory? || options[:directories]) then
          add_entry(zip_entry)
        end

        # Recurse into subdirectories (if requested).
        if zip_entry.directory? && options[:recursion] then
          archive(
            Dir.entries(path).reject do |e|
              e == '.' || e == '..'
            end.collect do |e|
              File.join(path, e)
            end,
            options.merge(:path_prefix => zip_entry_path)
          )
        end
      end

      nil
    end

    # Extracts the contents of the archive to _destination_, where _destination_
    # is a path to a directory which will contain the contents of the archive.
    # The destination path will be created if it does not already exist.
    #
    # _options_ is a Hash optionally containing the following:
    # <b>:directories</b>::
    #   When set to +true+ (the default), entries representing directories in
    #   the archive are extracted.  This happens after all non-directory entries
    #   are extracted so that directory metadata can be properly updated.
    # <b>:symlinks</b>::
    #   When set to +false+ (the default), entries representing symlinks in the
    #   archive are skipped.  When set to +true+, such entries are extracted.
    #   Exceptions may be raised on plaforms/file systems which do not support
    #   symlinks.
    # <b>:overwrite</b>::
    #   When set to <tt>:all</tt> (the default), files which already exist will
    #   be replaced.  When set to <tt>:older</tt>, such files will only be
    #   replaced if they are older according to their last modified times than
    #   the zip entry which would replace them.  When set to <tt>:none</tt>,
    #   such files will never be replaced.  Any other value is the same as
    #   <tt>:all</tt>.
    # <b>:create</b>::
    #   When set to +true+ (the default), files and directories which do not
    #   already exist will be extracted.  When set to +false+, only files and
    #   directories which already exist will be extracted (depending on the
    #   setting of <b>:overwrite</b>).
    # <b>:flatten</b>::
    #   When set to +false+ (the default), the directory paths containing
    #   extracted files will be created within +destination+ in order to contain
    #   the files.  When set to +true+, files are extracted directly to
    #   +destination+ and directory entries are skipped.
    # <b>:exclude</b>::
    #   Specifies a proc or lambda which takes a single argument containing a
    #   zip entry and returns +true+ if the entry should be skipped during
    #   extraction and +false+ if it should be extracted.
    # <b>:password</b>::
    #   Specifies a proc, lambda, or a String.  If a proc or lambda is used, it
    #   must take a single argument containing a zip entry and return a String
    #   to be used as a decryption key for the entry.  If a String is used, it
    #   will be used as a decryption key for all encrypted entries.
    # <b>:on_error</b>::
    #   Specifies a proc or lambda which is called when an exception is raised
    #   during the extraction of an entry.  It takes two arguments, a zip entry
    #   and an exception object generated while attempting to extract the entry.
    #   If <tt>:retry</tt> is returned, extraction of the entry is attempted
    #   again.  If <tt>:skip</tt> is returned, the entry is skipped.  Otherwise,
    #   the exception is raised.
    # Any other options which are supported by Archive::Zip::Entry#extract are
    # also supported.
    #
    # Raises Archive::Zip::IOError if called after #close.
    #
    # == Example
    #
    # An archive, <tt>archive.zip</tt>, contains:
    #   zip-test/
    #   zip-test/dir1/
    #   zip-test/dir1/file2.txt
    #   zip-test/dir2/
    #   zip-test/file1.txt
    #
    # A directory, <tt>extract4</tt>, contains:
    #   zip-test
    #   +- dir1
    #   +- file1.txt
    #
    # Extract the archive:
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract1')
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract2', :flatten => true)
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract3', :create => false)
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract('extract3', :create => true)
    #   end
    #
    #   Archive::Zip.open('archive.zip') do |z|
    #     z.extract( 'extract5', :exclude => lambda { |e| e.file? })
    #   end
    #
    # The directories contain:
    #   extract1 -> zip-test
    #               +- dir1
    #               |  +- file2.txt
    #               +- dir2
    #               +- file1.txt
    #
    #   extract2 -> file2.txt
    #               file1.txt
    #
    #   extract3 -> <empty>
    #
    #   extract4 -> zip-test
    #               +- dir2
    #               +- file1.txt       <- from archive contents
    #
    #   extract5 -> zip-test
    #               +- dir1
    #               +- dir2
    def extract(destination, options = {})
      raise IOError, 'closed archive' if @closed

      # Ensure that unspecified options have default values.
      options[:directories] = true  unless options.has_key?(:directories)
      options[:symlinks]    = false unless options.has_key?(:symlinks)
      options[:overwrite]   = :all  unless options[:overwrite] == :older ||
                                           options[:overwrite] == :never
      options[:create]      = true  unless options.has_key?(:create)
      options[:flatten]     = false unless options.has_key?(:flatten)

      # Flattening the archive structure implies that directory entries are
      # skipped.
      options[:directories] = false if options[:flatten]

      # First extract all non-directory entries.
      directories = []
      each do |entry|
        # Compute the target file path.
        file_path = entry.zip_path
        file_path = File.basename(file_path) if options[:flatten]
        file_path = File.join(destination, file_path)

        # Cache some information about the file path.
        file_exists = File.exist?(file_path)
        file_mtime = File.mtime(file_path) if file_exists

        begin
          # Skip this entry if so directed.
          if (! file_exists && ! options[:create]) ||
             (file_exists &&
              (options[:overwrite] == :never ||
               options[:overwrite] == :older && entry.mtime <= file_mtime)) ||
             (! options[:exclude].nil? && options[:exclude][entry]) then
            next
          end

          # Set the decryption key for the entry.
          if options[:password].kind_of?(String) then
            entry.password = options[:password]
          elsif ! options[:password].nil? then
            entry.password = options[:password][entry]
          end

          if entry.directory? then
            # Record the directories as they are encountered.
            directories << entry
          elsif entry.file? || (entry.symlink? && options[:symlinks]) then
            # Extract files and symlinks.
            entry.extract(
              options.merge(:file_path => file_path)
            )
          end
        rescue StandardError => error
          unless options[:on_error].nil? then
            case options[:on_error][entry, error]
            when :retry
              retry
            when :skip
            else
              raise
            end
          else
            raise
          end
        end
      end

      if options[:directories] then
        # Then extract the directory entries in depth first order so that time
        # stamps, ownerships, and permissions can be properly restored.
        directories.sort { |a, b| b.zip_path <=> a.zip_path }.each do |entry|
          begin
            entry.extract(
              options.merge(
                :file_path => File.join(destination, entry.zip_path)
              )
            )
          rescue StandardError => error
            unless options[:on_error].nil? then
              case options[:on_error][entry, error]
              when :retry
                retry
              when :skip
              else
                raise
              end
            else
              raise
            end
          end
        end
      end

      nil
    end

    private

    # <b>NOTE:</b> For now _io_ MUST be seekable and report such by returning
    # +true+ from its seekable? method.  See IO#seekable?.
    #
    # Raises Archive::Zip::IOError if _io_ is not seekable.
    def parse(io)
      # Error out if the IO object is not confirmed seekable.
      raise Zip::IOError, 'non-seekable IO object given' unless io.respond_to?(:seekable?) and io.seekable?

      socd_pos = find_central_directory(io)
      io.seek(socd_pos)
      # Parse each entry in the central directory.
      loop do
        signature = io.readbytes(4)
        break unless signature == CFH_SIGNATURE
        add_entry(Zip::Entry.parse(io))
      end
      @dirty = false
      # Maybe add support for digital signatures and ZIP64 records... Later

      nil
    end

    # Returns the file offset of the first record in the central directory.
    # _io_ must be a seekable, readable, IO-like object.
    #
    # Raises Archive::Zip::UnzipError if the end of central directory signature
    # is not found where expected or at all.
    def find_central_directory(io)
      # First find the offset to the end of central directory record.
      # It is expected that the variable length comment field will usually be
      # empty and as a result the initial value of eocd_offset is all that is
      # necessary.
      #
      # NOTE: A cleverly crafted comment could throw this thing off if the
      # comment itself looks like a valid end of central directory record.
      eocd_offset = -22
      loop do
        io.seek(eocd_offset, IO::SEEK_END)
        if io.readbytes(4) == EOCD_SIGNATURE then
          io.seek(16, IO::SEEK_CUR)
          break if io.readbytes(2).unpack('v')[0] == (eocd_offset + 22).abs
        end
        eocd_offset -= 1
      end
      # At this point, eocd_offset should point to the location of the end of
      # central directory record relative to the end of the archive.
      # Now, jump into the location in the record which contains a pointer to
      # the start of the central directory record and return the value.
      io.seek(eocd_offset + 16, IO::SEEK_END)
      return io.readbytes(4).unpack('V')[0]
    rescue Errno::EINVAL
      raise Zip::UnzipError, 'unable to locate end-of-central-directory record'
    end

    # Writes all the entries of this archive to _io_.  _io_ must be a writable,
    # IO-like object providing a _write_ method.  Returns the total number of
    # bytes written.
    def dump(io)
      bytes_written = 0
      entries = @entries.values
      entries.each do |entry|
        bytes_written += entry.dump_local_file_record(io, bytes_written)
      end
      central_directory_offset = bytes_written
      entries.each do |entry|
        bytes_written += entry.dump_central_file_record(io)
      end
      central_directory_length = bytes_written - central_directory_offset
      bytes_written += io.write(EOCD_SIGNATURE)
      bytes_written += io.write(
        [
          0,
          0,
          entries.length,
          entries.length,
          central_directory_length,
          central_directory_offset,
          comment.length
        ].pack('vvvvVVv')
      )
      bytes_written += io.write(comment)

      bytes_written
    end
  end
end
