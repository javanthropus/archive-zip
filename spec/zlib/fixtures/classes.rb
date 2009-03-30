class ZlibSpecs
  def self.compressed_file(&b)
    File.open(File.join(File.dirname(__FILE__), 'compressed_file.bin'), &b)
  end

  def self.compressed_data(&b)
    File.open(File.join(File.dirname(__FILE__), 'compressed_file.bin')) do |f|
      f.read
    end
  end

  def self.test_data
    File.open(File.join(File.dirname(__FILE__), 'raw_file.txt')) { |f| f.read }
  end
end
