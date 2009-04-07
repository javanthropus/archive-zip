class ZlibSpecs
  def self.compressed_file(&b)
    File.open(File.join(File.dirname(__FILE__), 'compressed_file.bin'), &b)
  end

  def self.compressed_data(&b)
    File.open(File.join(File.dirname(__FILE__), 'compressed_file.bin')) do |f|
      f.read
    end
  end

  def self.compressed_data_nocomp(&b)
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_nocomp.bin')
    ) do |f|
      f.read
    end
  end

  def self.compressed_data_minwin(&b)
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_minwin.bin')
    ) do |f|
      f.read
    end
  end

  def self.compressed_data_minmem(&b)
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_minmem.bin')
    ) do |f|
      f.read
    end
  end

  def self.compressed_data_huffman(&b)
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_huffman.bin')
    ) do |f|
      f.read
    end
  end

  def self.test_data
    File.open(File.join(File.dirname(__FILE__), 'raw_file.txt')) { |f| f.read }
  end
end
