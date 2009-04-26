class TraditionalEncryptionSpecs
  class << self
    def password
      'p455w0rd'
    end

    def mtime
      Time.at(0)
    end

    def encrypted_data
      File.open(File.join(File.dirname(__FILE__), 'encrypted_file.bin')) do |f|
        block_given? ? yield(f) : f.read
      end
    end

    def test_data
      File.open(File.join(File.dirname(__FILE__), 'raw_file.txt')) do |f|
        block_given? ? yield(f) : f.read
      end
    end
  end
end
