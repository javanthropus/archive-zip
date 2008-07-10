module Archive; class Zip; module ExtraField
  # Archive::Zip::Entry::ExtraField::Raw represents an unknown extra field.  It
  # is used to store extra fields the Archive::Zip library does not directly
  # support.
  class Raw
    # Simply stores _header_id_ and _data_ for later reproduction by #dump.
    # This is essentially and alias for #new.
    def self.parse(header_id, data)
      new(header_id, data)
    end

    # Simply stores _header_id_ and _data_ for later reproduction by #dump.
    def initialize(header_id, data)
      @header_id = header_id
      @data = data
    end

    # Returns the header ID for this ExtraField.
    attr_reader :header_id
    # Returns the data contained within this ExtraField.
    attr_reader :data

    # This method signature is part of the interface contract expected by
    # Archive::Zip::Entry for extra field objects.
    #
    # Returns a String suitable to writing to a ZIP archive file which contains
    # the data for this object.
    def dump
      [header_id, @data.size].pack('vv') + @data
    end
  end
end; end; end
