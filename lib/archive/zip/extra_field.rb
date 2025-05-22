# encoding: UTF-8

require 'archive/zip/error'

module Archive; class Zip
  module ExtraField
    # A Hash used to map extra field header identifiers to extra field classes.
    EXTRA_FIELDS = {}

    def self.parse_many(bytes)
      extra_fields = []
      idx = 0
      while idx < bytes.size do
        raise EntryError, 'insufficient data available' if bytes.size < idx + 4
        header_id, data_size = bytes[idx, 4].unpack('vv')
        idx += 4

        if bytes.size < idx + data_size
          raise EntryError, 'insufficient data available'
        end
        data = bytes[idx, data_size]
        idx += data_size

        extra_fields << yield(header_id, data)
      end
      extra_fields
    end

    def self.parse_many_central(bytes)
      parse_many(bytes) do |header_id, data|
        EXTRA_FIELDS.fetch(header_id, Raw).parse_central(header_id, data)
      end
    end

    def self.parse_many_local(bytes)
      parse_many(bytes) do |header_id, data|
        EXTRA_FIELDS.fetch(header_id, Raw).parse_local(header_id, data)
      end
    end
  end
end; end

# Load the standard extra field classes.
require 'archive/zip/extra_field/extended_timestamp'
require 'archive/zip/extra_field/raw'
require 'archive/zip/extra_field/unix'
