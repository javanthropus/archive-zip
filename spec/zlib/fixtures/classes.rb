class ZlibSpecs
  def self.compressed_data
    File.open(File.join(File.dirname(__FILE__), 'compressed_file.bin')) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_nocomp
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_nocomp.bin')
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_minwin
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_minwin.bin')
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_minmem
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_minmem.bin')
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_huffman
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_huffman.bin')
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_gzip
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_gzip.bin')
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.compressed_data_raw
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_raw.bin')
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.test_data
    File.open(File.join(File.dirname(__FILE__), 'raw_file.txt')) { |f| f.read }
  end
end
