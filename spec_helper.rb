# Add the lib directory for this module to the search path.
$: << File.join(File.dirname(__FILE__), 'lib')

unless ENV['MSPEC_RUNNER']
  begin
    require 'mspec/version'
    require 'mspec/helpers'
    require 'mspec/guards'
    require 'mspec/runner/shared'
    require 'mspec/matchers/complain'

    # Code to setup HOME directory correctly on Windows
    # This duplicates Ruby 1.9 semantics for defining HOME
    platform_is :windows do
      if ENV['HOME']
        ENV['HOME'] = ENV['HOME'].tr '\\', '/'
      elsif ENV['HOMEDIR'] && ENV['HOMEDRIVE']
        ENV['HOME'] = File.join(ENV['HOMEDRIVE'], ENV['HOMEDIR'])
      elsif ENV['HOMEDIR']
        ENV['HOME'] = ENV['HOMEDIR']
      elsif ENV['HOMEDRIVE']
        ENV['HOME'] = ENV['HOMEDRIVE']
      elsif ENV['USERPROFILE']
        ENV['HOME'] = ENV['USERPROFILE']
      else
        puts "No suitable HOME environment found. This means that all of"
        puts "HOME, HOMEDIR, HOMEDRIVE, and USERPROFILE are not set"
        exit 1
      end
    end

    TOLERANCE = 0.00003 unless Object.const_defined?(:TOLERANCE)
  rescue LoadError
    puts "Please install the MSpec gem to run the specs."
    exit 1
  end
end

minimum_version = "1.5.17"
unless MSpec::VERSION >= minimum_version
  puts "Please install MSpec version >= #{minimum_version} to run the specs"
  exit 1
end

# Set a flag when encodings are supported.
MSpec.enable_feature :encoding if Object.const_defined?(:Encoding)

$VERBOSE = nil unless ENV['OUTPUT_WARNINGS']
