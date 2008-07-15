require 'archive/zip/error'

module Archive; class Zip; module ExtraField
  # Archive::Zip::Entry::ExtraField::ExtendedTimestamp represents an extra field
  # which optionally contains the last modified time, last accessed time, and
  # file creation time for a ZIP archive entry and stored in a Unix time format
  # (seconds since the epoc).
  class ExtendedTimestamp
    # The identifier reserved for this extra field type.
    ID = 0x5455

    # Register this extra field for use.
    EXTRA_FIELDS[ID] = self

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Parses _data_ which is expected to be a String formatted according to the
    # documentation provided with InfoZip's sources.
    #
    # Raises Archive::Zip::ExtraFieldError if _data_ contains invalid data.
    def self.parse(data)
      unless data.size == 5 || data.size == 9 || data.size == 13 then
        raise Zip::ExtraFieldError,
          "invalid size for extended timestamp: #{data.size}"
      end
      flags, *times = data.unpack('C' + 'V' * ((data.size - 1) / 4))
      mtime = nil
      atime = nil
      crtime = nil
      if flags & 0b001 != 0 then
        if times.size == 0 then
          # Report an error if the flags indicate that the last modified time
          # field should be present when it is not.
          raise Zip::ExtraFieldError,
            'corrupt extended timestamp: last modified time field not present'
        end
        mtime = Time.at(times.shift)
      end
      if flags & 0b010 != 0 then
        # HACK:
        # InfoZip does not follow their own documentation for this extra field
        # when creating one for an entry's central file record.  They flag that
        # the atime field should be present when it is not.  Ignore the flag in
        # that case.
        if times.size > 0 then
          atime = Time.at(times.shift)
        end
      end
      if flags & 0b100 != 0 then
        if times.size == 0 then
          # Report an error if the flags indicate that the file creation time
          # field should be present when it is not.
          raise Zip::ExtraFieldError,
            'corrupt extended timestamp: file creation time field not present'
        end
        crtime = Time.at(times.shift)
      end
      new(mtime, atime, crtime)
    end

    # Creates a new instance of this class.  _mtime_, _atime_, and _crtime_
    # should be Time instances or +nil+.  When set to +nil+ the field is
    # considered to be unset and will not be stored in the archive.
    def initialize(mtime, atime, crtime)
      @mtime = mtime
      @atime = atime
      @crtime = crtime
    end

    # The last modified time for an entry.
    attr_accessor :mtime
    # The last accessed time for an entry.
    attr_accessor :atime
    # The creation time for an entry.
    attr_accessor :crtime

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a ZIP archive file which contains
    # the data for this object.
    def dump
      flags = 0
      times = []
      unless mtime.nil? then
        flags |= 0b001
        times << mtime.to_i
      end
      unless atime.nil? then
        flags |= 0b010
        times << atime.to_i
      end
      unless crtime.nil? then
        flags |= 0b100
        times << crtime.to_i
      end
      ([ID, 4 * times.size + 1, flags] + times).pack('vvC' + 'V' * times.size)
    end
  end
end; end; end
