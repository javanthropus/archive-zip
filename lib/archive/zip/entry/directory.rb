# encoding: UTF-8

module Archive; class Zip; module Entry
# Archive::Zip::Entry::Directory represents a directory entry within a Zip
# archive.
class Directory < AbstractEntry
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
  #   Specifies the path to which this entry will be extracted.  Defaults to the
  #   zip path of this entry.
  # <b>:permissions</b>::
  #   When set to +false+ (the default), POSIX mode/permission bits will be
  #   ignored.  Otherwise, they will be restored if possible.
  # <b>:ownerships</b>::
  #   When set to +false+ (the default), user and group ownerships will be
  #   ignored.  On most systems, only a superuser is able to change ownerships,
  #   so setting this option to +true+ as a regular user may have
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
end
end; end; end
