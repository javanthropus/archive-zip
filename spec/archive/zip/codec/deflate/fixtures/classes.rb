class DeflateSpecs
  def self.compressed_data_nocomp(&b)
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file_nocomp.bin')
    ) do |f|
      f.read
    end
  end

  def self.compressed_data
    File.open(
      File.join(File.dirname(__FILE__), 'compressed_file.bin')
    ) do |f|
      block_given? ? yield(f) : f.read
    end
  end

  def self.test_data
    File.open(File.join(File.dirname(__FILE__), 'raw_file.txt')) do |f|
      block_given? ? yield(f) : f.read
    end
  end
end
