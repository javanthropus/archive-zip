# encoding: UTF-8

require 'archive/support/ioextensions'
require 'archive/zip/error'
require 'archive/zip/extra_field'
require 'archive/zip/general_purpose_flags'

module Archive; class Zip
class CentralDirectoryHeader
  # Parses a central file record and returns a CFHRecord instance containing
  # the parsed data.  _io_ must be a readable, IO-like object which is
  # positioned at the start of a central file record following the signature
  # for that record.
  def self.parse(io)
    cfh = new

    cfh.made_by_version,
    cfh.extraction_version =
      IOExtensions.read_exactly(io, 4).unpack('vv')

    cfh.general_purpose_flags = GeneralPurposeFlags.parse(io)

    cfh.compression_method,
    dos_mtime =
      IOExtensions.read_exactly(io, 6).unpack('vV')

    cfh.data_descriptor = DataDescriptor.parse(io)

    file_name_length,
    extra_fields_length,
    comment_length,
    cfh.disk_number_start,
    cfh.internal_file_attributes,
    cfh.external_file_attributes,
    cfh.local_header_position =
      IOExtensions.read_exactly(io, 18).unpack('vvvvvVV')

    cfh.zip_path = IOExtensions.read_exactly(io, file_name_length)
    cfh.extra_fields = ExtraField.parse_many_central(
      IOExtensions.read_exactly(io, extra_fields_length)
    )
    cfh.comment = IOExtensions.read_exactly(io, comment_length)

    # Convert from MSDOS time to Unix time.
    cfh.mtime = DOSTime.new(dos_mtime).to_time

    cfh
  rescue EOFError
    raise Zip::EntryError, 'unexpected end of file'
  end

  attr_accessor :made_by_version
  attr_accessor :extraction_version
  attr_accessor :general_purpose_flags
  attr_accessor :compression_method
  attr_accessor :mtime
  attr_accessor :data_descriptor
  attr_accessor :disk_number_start
  attr_accessor :internal_file_attributes
  attr_accessor :external_file_attributes
  attr_accessor :local_header_position
  attr_accessor :zip_path
  attr_accessor :extra_fields
  attr_accessor :comment
end
end; end
