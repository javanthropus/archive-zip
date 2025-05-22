# encoding: UTF-8

require 'archive/support/stringio'
require 'archive/zip/error'

module Archive; class Zip; module Entry
# Archive::Zip::Entry::File represents a file entry within a Zip archive.
class File < AbstractEntry
  # Creates a new file entry where _zip_path_ is the path to the entry in the
  # ZIP archive.  The Archive::Zip::Codec::Deflate codec with the default
  # compression level set (NORMAL) is used by default for compression.
  # _raw_data_, if specified, must be a readable, IO-like object containing
  # possibly compressed/encrypted file data for the entry.  It is intended to be
  # used primarily by the Archive::Zip::Entry.parse class method.
  def initialize(zip_path, raw_data = nil)
    super(zip_path, raw_data)
    @file_path = nil
    @file_data = nil
    @compression_codec = Zip::Codec::Deflate.new
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

  # Sets the decryption password.
  def password=(password)
    unless @raw_data.nil? then
      @file_data = nil
    end
    @password = password
  end

  # The path to a file whose contents are to be used for uncompressed file data.
  # This will be +nil+ if the +file_data+ attribute is set directly.
  attr_reader :file_path

  # Sets the +file_path+ attribute to _file_path_ which should be a String
  # usable with File#new to open a file for reading which will provide the
  # IO-like object for the +file_data+ attribute.
  def file_path=(file_path)
    @file_data = nil
    @raw_data = nil
    @file_path = file_path
  end

  # Returns a readable, IO-like object containing uncompressed file data.
  #
  # <b>NOTE:</b> It is the responsibility of the user of this attribute to
  # ensure that the #close method of the returned IO-like object is called when
  # the object is no longer needed.
  def file_data
    return @file_data unless @file_data.nil? || @file_data.closed?

    if raw_data.nil? then
      if @file_path.nil? then
        simulated_raw_data = StringIO.new('', 'rb')
      else
        simulated_raw_data = ::File.new(@file_path, 'rb')
      end
      # Ensure that the IO-like object can return a data descriptor so that
      # it's possible to verify extraction later if desired.
      @file_data = Zip::Codec::Store.new.decompressor(
        IO::LikeHelpers::IOWrapper.new(simulated_raw_data)
      )
    else
      raw_data.seek(0)
      @file_data = compression_codec.decompressor(
        encryption_codec.decryptor(raw_data, password)
      )
    end
    @file_data
  end

  # Sets the +file_data+ attribute of this object to _file_data_.  _file_data_
  # must be a readable, IO-like object.
  #
  # <b>NOTE:</b> As a side effect, the +file_path+ and +raw_data+ attributes for
  # this object will be set to +nil+.
  def file_data=(file_data)
    @file_path = nil
    self.raw_data = nil
    @file_data = file_data
    # Ensure that the IO-like object can return CRC32 and data size information
    # so that it's possible to verify extraction later if desired.
    unless @file_data.respond_to?(:data_descriptor) then
      @file_data = Zip::Codec::Store.new.decompressor(@file_data)
    end
    @file_data
  end

  # Extracts this entry.
  #
  # _options_ is a Hash optionally containing the following:
  # <b>:file_path</b>::
  #   Specifies the path to which this entry will be extracted.  Defaults to the
  #   zip path of this entry.
  # <b>:permissions</b>::
  #   When set to +false+ (the default), POSIX mode/permission bits will be
  #   ignored.  Otherwise, they will be restored if possible.
  # <b>:ownerships</b>::
  #   When set to +false+ (the default), user and group ownerships will be
  #   ignored.  On most systems, only a superuser is able to change ownerships,
  #   so setting this option to +true+ as a regular user may have no effect.
  # <b>:times</b>::
  #   When set to +false+ (the default), last accessed and last modified times
  #   will be ignored.  Otherwise, they will be restored if possible.
  #
  # Raises Archive::Zip::EntryError if the extracted file data appears corrupt.
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
    IO.copy_stream(file_data, file_path)

    # Verify that the extracted data is good.
    begin
      unless expected_data_descriptor.nil? then
        expected_data_descriptor.verify(file_data.data_descriptor)
      end
    rescue => e
      raise Zip::EntryError, "`#{zip_path}': #{e.message}"
    end

    # Restore the metadata.
    ::File.chmod(mode, file_path) if restore_permissions
    ::File.chown(uid, gid, file_path) if restore_ownerships
    ::File.utime(atime, mtime, file_path) if restore_times

    # Attempt to rewind the file data back to the beginning, but ignore errors.
    begin
      file_data.seek(0)
    rescue
      # Ignore.
    end

    nil
  end

  private

  # Write the file data to _io_.
  def dump_file_data(io)
    IO.copy_stream(file_data, io)

    # Attempt to ensure that the file data will still be in a readable state at
    # the beginning of the data for the next user, but close it if possible in
    # order to conserve resources.
    if file_path.nil? then
      # When the file_path attribute is not set, the file_data method cannot
      # reinitialize the IO object it returns, so attempt to rewind the file
      # data back to the beginning, but ignore errors.
      begin
        file_data.seek(0)
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
