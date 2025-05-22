# encoding: UTF-8

require 'archive/support/ioextensions'
require 'archive/zip/error'
require 'archive/zip/extra_field'
require 'archive/zip/general_purpose_flags'

module Archive; class Zip
class LocalFileHeader
  # Parses a local file record and returns a LFHRecord instance containing the
  # parsed data.  _io_ must be a readable, IO-like object which is positioned
  # at the start of a local file record following the signature for that
  # record.
  #
  # If the record to be parsed is flagged to have a trailing data descriptor
  # record, _expected_compressed_size_ must be set to an integer counting the
  # number of bytes of compressed data to skip in order to find the trailing
  # data descriptor record, and _io_ must be seekable by providing _pos_ and
  # <i>pos=</i> methods.
  def self.parse(io, expected_compressed_size = nil)
    lfh = new

    lfh.extraction_version = IOExtensions.read_exactly(io, 2).unpack1('v')

    lfh.general_purpose_flags = GeneralPurposeFlags.parse(io)

    lfh.compression_method,
    dos_mtime =
      IOExtensions.read_exactly(io, 6).unpack('vV')

    lfh.data_descriptor = DataDescriptor.parse(io)

    file_name_length,
    extra_fields_length =
      IOExtensions.read_exactly(io, 4).unpack('vv')

    lfh.zip_path = IOExtensions.read_exactly(io, file_name_length)
    lfh.extra_fields = ExtraField.parse_many_local(
      IOExtensions.read_exactly(io, extra_fields_length)
    )

    # Convert from MSDOS time to Unix time.
    lfh.mtime = DOSTime.new(dos_mtime).to_time

    if lfh.general_purpose_flags.data_descriptor_follows? &&
      ! expected_compressed_size.nil? then
      saved_pos = io.pos
      io.pos += expected_compressed_size
      # Because the ZIP specification has a history of murkiness, some
      # libraries create trailing data descriptor records with a preceding
      # signature while others do not.
      # This handles both cases.
      possible_signature = IOExtensions.read_exactly(io, 4)
      io.pos -= 4 if possible_signature != DD_SIGNATURE
      lfh.data_descriptor = DataDescriptor.parse(io)
      io.pos = saved_pos
    end

    lfh
  rescue EOFError
    raise Zip::EntryError, 'unexpected end of file'
  end

  attr_accessor :extraction_version
  attr_accessor :general_purpose_flags
  attr_accessor :compression_method
  attr_accessor :mtime
  attr_accessor :data_descriptor
  attr_accessor :zip_path
  attr_accessor :extra_fields
end
end; end
