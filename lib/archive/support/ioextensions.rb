# encoding: UTF-8

# IOExtensions provides convenience wrappers for certain IO functionality.
module IOExtensions
  # Reads and returns exactly _length_ bytes from _io_ using the read method on
  # _io_.  If there is insufficient data available, an EOFError is raised.
  def self.read_exactly(io, length)
    result = io.read(length)
    if result.nil? || result.bytesize < length
      raise EOFError, 'unexpected end of file'
    end
    result
  end
end
