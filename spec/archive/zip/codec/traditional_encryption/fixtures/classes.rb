# encoding: UTF-8

require 'io/like_helpers/io_wrapper'

require 'archive/support/stringio'

class TraditionalEncryptionSpecs
  def self.password
    'p455w0rd'
  end

  def self.mtime
    Time.local(1979, 12, 31, 18, 0, 0)
  end

  def self.encrypted_data(&b)
    read_data(File.join(File.dirname(__FILE__), 'encrypted_file.bin'), &b)
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
