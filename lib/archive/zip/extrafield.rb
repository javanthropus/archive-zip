module Archive; class Zip
  module ExtraField
    # A Hash used to map extra field header identifiers to extra field classes.
    EXTRA_FIELDS = {}

    # Returns an instance of an extra field class by selecting the class using
    # _header_id_ and passing _data_ to the class' _parse_ method.  If there is
    # no mapping from a given value of _header_id_ to an extra field class, an
    # instance of Archive::Zip::Entry::ExtraField::Raw is returned.
    def self.parse(header_id, data)
      if EXTRA_FIELDS.has_key?(header_id) then
        EXTRA_FIELDS[header_id].parse(data)
      else
        Raw.parse(header_id, data)
      end
    end
  end
end; end

# Load the standard extra field classes.
require 'archive/zip/extrafield/extendedtimestamp'
require 'archive/zip/extrafield/raw'
require 'archive/zip/extrafield/unix'
