# encoding: UTF-8

require 'archive/zip/error'

module Archive; class Zip; module Entry
# Archive::Zip::Entry::Symlink represents a symlink entry withing a Zip archive.
class Symlink < AbstractEntry
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

  # Returns the link target for this entry.
  #
  # Raises Archive::Zip::EntryError if decoding the link target from an archive
  # is required but fails.
  def link_target
    return @link_target unless @link_target.nil?

    raw_data.seek(0)
    compression_codec.decompressor(
      encryption_codec.decryptor(raw_data, password)
    ) do |decompressor|
      @link_target = decompressor.read
      # Verify that the extracted data is good.
      begin
        unless expected_data_descriptor.nil? then
          expected_data_descriptor.verify(decompressor.data_descriptor)
        end
      rescue => e
        raise Zip::EntryError, "`#{zip_path}': #{e.message}"
      end
    end
    @link_target
  end

  # Sets the link target for this entry.  As a side effect, the raw_data
  # attribute is set to +nil+.
  def link_target=(link_target)
    self.raw_data = nil
    @link_target = link_target
  end

  # Extracts this entry.
  #
  # _options_ is a Hash optionally containing the following:
  # <b>:file_path</b>::
  #   Specifies the path to which this entry will be extracted.  Defaults to the
  #   zip path of this entry.
  # <b>:permissions</b>::
  #   When set to +false+ (the default), POSIX mode/permission bits will be
  #   ignored.  Otherwise, they will be restored if possible.  Not supported on
  #   all platforms.
  # <b>:ownerships</b>::
  #   When set to +false+ (the default), user and group ownerships will be
  #   ignored.  On most systems, only a superuser is able to change ownerships,
  #   so setting this option to +true+ as a regular user may have no effect.
  #   Not supported on all platforms.
  #
  # Raises Archive::Zip::EntryError if the link_target attribute is not
  # specified.
  def extract(options = {})
    raise Zip::EntryError, 'link_target is nil' if link_target.nil?

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
  def dump_file_data(io)
    io.write(@link_target)
  end
end
end; end; end
