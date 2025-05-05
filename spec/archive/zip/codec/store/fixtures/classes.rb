# encoding: UTF-8

require 'io/like_helpers/io_wrapper'

require 'archive/support/stringio'

class StoreSpecs
  def self.test_data(&b)
    read_data(File.join(File.dirname(__FILE__), 'raw_file.txt'), &b)
  end

  class << self
    alias_method :compressed_data, :test_data
  end

  def self.string_io(data = ''.b, mode = 'r+b', &b)
    IO::LikeHelpers::IOWrapper.open(StringIO.new(data, mode), &b)
  end

  private

  def self.read_data(path, &b)
    File.open(path, 'rb') do |f|
      return f.read unless block_given?
      IO::LikeHelpers::IOWrapper.open(f, &b)
    end
  end
end
