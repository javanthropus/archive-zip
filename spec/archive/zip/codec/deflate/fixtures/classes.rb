# encoding: UTF-8

require 'io/like_helpers/io_wrapper'

require 'archive/support/stringio'

class DeflateSpecs
  def self.compressed_data(&b)
    read_data(File.join(File.dirname(__FILE__), 'compressed_file.bin'), &b)
  end

  def self.compressed_data_nocomp(&b)
    read_data(
      File.join(File.dirname(__FILE__), 'compressed_file_nocomp.bin'), &b
    )
  end

  def self.compressed_data_minmem(&b)
    read_data(
      File.join(File.dirname(__FILE__), 'compressed_file_minmem.bin'), &b
    )
  end

  def self.compressed_data_huffman(&b)
    read_data(
      File.join(File.dirname(__FILE__), 'compressed_file_huffman.bin'), &b
    )
  end

  def self.test_data(&b)
    read_data(File.join(File.dirname(__FILE__), 'raw_file.txt'), &b)
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
