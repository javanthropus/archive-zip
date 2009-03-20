require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rubygems'

# The Unix name of this project.
PKG_NAME    = 'archive-zip'

# The current version of this gem.  Increment for each new release.
PKG_VERSION = '0.3.0'

# The location where documentation should be created.
# NOTE: This MUST have a slash on the end or document publishing will not work
# correctly.
LOCAL_DOCS  = 'doc/'

# The location for published documents to be copied.
remote_user = ENV['REMOTE_USER'].nil? ? '' : ENV['REMOTE_USER'] + '@'
remote_host = ENV['REMOTE_HOST'].nil? ?
  'rubyforge.org:' :
  ENV['REMOTE_HOST'] + ':'
remote_path = ENV['REMOTE_PATH'].nil? ?
  "/var/www/gforge-projects/#{PKG_NAME}" :
  ENV['REMOTE_PATH']
remote_path += '/' unless remote_path[-1, 1] == '/'
REMOTE_DOCS = "#{remote_user}#{remote_host}#{remote_path}"

# The files which actually do something.
LIB_FILES   = FileList.new(
  'lib/**/*.rb'
)

# Files used to run tests.
TEST_FILES  = FileList.new(
  'test/**/*.rb'
)

# Spec files used with mspec and their support files.
SPEC_FILES  = FileList.new(
  'default.mspec',
  'spec_helper.rb',
  'spec/**/*'
)

# Files to be included for documentation purposes only.
DOC_FILES   = FileList.new(
  'CONTRIBUTORS',
  'HACKING',
  'LICENSE',
  'GPL',
  'LEGAL',
  'NEWS',
  'README'
)

# Files which do not match another category.
MISC_FILES  = FileList.new(
  'MANIFEST'
)

# All the files which are to be included within the package.
PKG_FILES   = LIB_FILES + DOC_FILES + MISC_FILES

# Files used by the rdoc task.
RDOC_FILES  = LIB_FILES + DOC_FILES

# Make sure that :clean and :clobber will not whack the repository files.
CLEAN.exclude('.git/**')
# Vim swap files are fair game for clean up.
CLEAN.include('**/.*.sw?')

spec = Gem::Specification.new do |s|
  s.name          = PKG_NAME
  s.version       = PKG_VERSION
  s.platform      = Gem::Platform::RUBY
  s.author        = 'Jeremy Bopp'
  s.email         = 'jeremy at bopp dot net'
  s.summary       = 'Simple, extensible, pure Ruby ZIP archive support.'
  s.description   = <<-EOF
Archive::Zip provides a simple Ruby-esque interface to creating, extracting, and
updating ZIP archives.  This implementation is 100% Ruby and loosely modeled on
the archive creation and extraction capabilities of InfoZip's zip and unzip
tools.
  EOF
  s.rubyforge_project = PKG_NAME
  s.homepage      = "http://#{PKG_NAME}.rubyforge.org"
  s.files         = PKG_FILES
  s.required_ruby_version = '>= 1.8.1'
  s.add_dependency('io-like', '>= 0.1.0')

  s.has_rdoc      = true
  s.extra_rdoc_files = DOC_FILES
  s.rdoc_options  << '--title' << 'Archive::Zip Documentation' <<
                     '--charset' << 'utf-8' <<
                     '--line-numbers' << '--inline-source'
end

# Ensure that the packaging tasks which will be created verify the manifest
# first.
task :gem => :check_manifest
task :package => :check_manifest

# Create the gem and package tasks.
Rake::GemPackageTask.new(spec) do |t|
  t.need_tar_gz = true
end

# Create the rdoc task.
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir   = LOCAL_DOCS
  rdoc.title      = 'Archive::Zip Documentation'
  rdoc.rdoc_files = RDOC_FILES
  rdoc.main       = 'README'

  # Set miscellaneous options to settings I like.
  rdoc.options    << '--line-numbers' << '--inline-source'
  rdoc.options    << '--charset' << 'utf-8'

  # Use the allison template if available.
  allison_path    = `allison --path 2>/dev/null`.chomp
  rdoc.template   = allison_path unless allison_path.empty?
end

desc 'Tag the current HEAD with the current version string'
task :tag do
  sh "git tag -s -m 'Release v#{PKG_VERSION}' v#{PKG_VERSION}"
end

desc 'Create the CHANGELOG file'
task :changelog do
  File.open('CHANGELOG', 'w') do |changelog|
    IO.popen('git log') do |git|
      git.each do |line|
        # Protect email addresses from spammers.
        line.gsub!(
          /([a-z0-9!\#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!\#$%&'*+\/=?^_`{|}~-]+)*)@((?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)/i
        ) { |match| "#{$1} at #{$2.gsub('.', ' dot ')}" }
        changelog.puts(line)
      end
    end
  end
end

desc 'Create/Update the MANIFEST file'
task :manifest do
  File.open('MANIFEST', 'w') { |f| f.puts(PKG_FILES.sort) }
end

desc 'Verify the manifest'
task :check_manifest do
  unless File.exist?('MANIFEST') then
    raise "File not found - `MANIFEST': Execute the manifest task"
  end
  manifest_files = File.readlines('MANIFEST').map { |line| line.chomp }.uniq
  pkg_files = PKG_FILES.uniq
  if manifest_files.sort != pkg_files.sort then
    common_files = manifest_files & pkg_files
    manifest_files.delete_if { |file| common_files.include?(file) }
    pkg_files.delete_if { |file| common_files.include?(file) }
    $stderr.puts('The manifest does not match the package file list')
    unless manifest_files.empty? then
      $stderr.puts("  Extraneous files:\n    " + manifest_files.join("\n    "))
    end
    unless pkg_files.empty?
      $stderr.puts("  Missing files:\n    " + pkg_files.join("\n    "))
    end
    exit 1
  end
end

desc 'Publish the project documentation'
task :publish => [:rdoc] do
  sh "rsync -r --delete \"#{LOCAL_DOCS}\" \"#{REMOTE_DOCS}\""
end

# Create the test task.
desc 'Run tests'
task :test do
  sh "mspec"
end

# Clean up to a pristine state.
task :clobber => [:clobber_package, :clobber_rdoc]

desc 'An alias for the gem target'
task :default => [:gem]
