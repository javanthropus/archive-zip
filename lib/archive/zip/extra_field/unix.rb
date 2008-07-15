require 'archive/zip/error'

module Archive; class Zip; module ExtraField
  # Archive::Zip::Entry::ExtraField::Unix represents an extra field which
  # contains the last modified time, last accessed time, user name, and group
  # name for a ZIP archive entry.  Times are in Unix time format (seconds since
  # the epoc).
  #
  # This class also optionally stores either major and minor numbers for devices
  # or a link target for either hard or soft links.  Which is in use when given
  # and instance of this class depends upon the external file attributes for the
  # ZIP archive entry associated with this extra field.
  class Unix
    # The identifier reserved for this extra field type.
    ID = 0x000d

    # Register this extra field for use.
    EXTRA_FIELDS[ID] = self

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Parses _data_ which is expected to be a String formatted according to the
    # official ZIP specification.
    #
    # Raises Archive::Zip::ExtraFieldError if _data_ contains invalid data.
    def self.parse(data)
      unless data.length >= 12 then
        raise Zip::ExtraFieldError, "invalid size for Unix data: #{data.size}"
      end
      atime, mtime, uid, gid, rest = data.unpack('VVvva')
      new(Time.at(mtime), Time.at(atime), uid, gid, rest)
    end

    # Creates a new instance of this class.  _mtime_ and _atime_ should be Time
    # instances.  _uid_ and _gid_ should be user and group names as strings
    # respectively.  _data_ should be a string containing either major and minor
    # device numbers consecutively packed as little endian, 4-byte, unsigned
    # integers (see the _V_ directive of Array#pack) or a path to use as a link
    # target.
    def initialize(mtime, atime, uid, gid, data = '')
      @mtime = mtime
      @atime = atime
      @uid = uid
      @gid = gid
      @data = data
    end

    # A Time object representing the last accessed time for an entry.
    attr_accessor :atime
    # A Time object representing the last modified time for an entry.
    attr_accessor :mtime
    # An integer representing the user ownership for an entry.
    attr_accessor :uid
    # An integer representing the group ownership for an entry.
    attr_accessor :gid

    # Attempts to return a two element array representing the major and minor
    # device numbers which may be stored in the variable data section of this
    # object.
    def device_numbers
      @data.unpack('VV')
    end

    # Takes a two element array containing major and minor device numbers and
    # stores the numbers into the variable data section of this object.
    def device_numbers=(major_minor)
      @data = major_minor.pack('VV')
    end

    # Attempts to return a string representing the path of a file which is
    # either a symlink or hard link target which may be stored in the variable
    # data section of this object.
    def link_target
      @data
    end

    # Takes a string containing the path to a file which is either a symlink or
    # a hardlink target and stores it in the variable data section of this
    # object.
    def link_target=(link_target)
      @data = link_target
    end

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a ZIP archive file which contains
    # the data for this object.
    def dump
      [
        ID,
        12 + @data.size,
        @atime.to_i,
        @mtime.to_i,
        @uid,
        @gid
      ].pack('vvVVvv') + @data
    end
  end
end; end; end
