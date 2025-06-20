# encoding: UTF-8
# -*- ruby -*-

require 'rubygems'

require 'erb'
require 'rake/testtask'
require 'rubygems/package_task'
require 'rake/clean'
require 'yard'

# Load the gemspec file for this project.
GEMSPEC = Dir['*.gemspec'].first
SPEC = eval(File.read(GEMSPEC), nil, GEMSPEC)

# A dynamically generated list of files that should match the manifest (the
# contents of SPEC.files).  The idea is for this list to contain all project
# files except for those that have been explicitly excluded.  This list will be
# compared with the manifest from the SPEC in order to help catch the addition
# or removal of files to or from the project that have not been accounted for
# either by an exclusion here or an inclusion in the SPEC manifest.
#
# NOTE:
# It is critical that the manifest is *not* automatically generated via globbing
# and the like; otherwise, this will yield a simple comparison between
# redundantly generated lists of files that probably will not protect the
# project from the unintentional inclusion or exclusion of files in the
# distribution.
IGNORE_RULE = %r{\A(?<include>!?)(?<path>(\\.| *[^# \n])*) *(#.*)?\n*\z}
PKG_FILES = FileList.new('**/*') do |files|
  # Exclude directories.
  files.exclude { |file| File.directory?(file) }

  # Parse the ignore rules.
  rules = File.open('.ruby-gems.ignore') do |f|
    f.filter_map do |line|
      rule = IGNORE_RULE.match(line).named_captures

      # If the include operator wasn't specified in the rule, then the operation
      # is to exclude.
      exclude = rule['include'].empty?
      path = rule['path']
      next if path.empty?

      # Replace all escapes in the path.
      path.gsub!(%r{\\(.)}, "\\1")

      # If there is no / at the beginning or middle of the path, then the path
      # matches at any level, so prepend the glob for that.
      path.insert(0, '{**/,}') if path =~ %r{\A[^/]+/?\z}

      # A trailing slash means to match everything under the path, so append the
      # glob for that.
      path += '**/*' if path.end_with?('/')

      # A leading / is redundant since it means to root matches at the same
      # level as the ignore file.
      path.sub!(%r{^/+}, '')

      {exclude: exclude, path: path}
    end
  end

  # Add an exclude rule based on the set of ignore rules.
  # A given file is presumed to be included at first.  The last ignore rule
  # whose path matches the file dictates whether or not the file is excluded by
  # way of the rules exclude setting.
  fnmatch_flags = File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB
  files.exclude do |file|
    rule = rules.reverse_each
      .find { |rule| File.fnmatch(rule[:path], file, fnmatch_flags) }
    next false if rule.nil?
    rule[:exclude]
  end
end

# Make sure that :clean and :clobber will not whack the repository files.
CLEAN.exclude('.git/**')
# Vim swap files are fair game for clean up.
CLEAN.include('**/.*.sw?')

# Returns the value of the VERSION environment variable as a Gem::Version object
# assuming it is set and a valid Gem version string.  Otherwise, raises an
# exception.
def get_version_argument
  version = ENV['VERSION']
  if version.to_s.empty?
    raise "No version specified: Add VERSION=X.Y.Z to the command line"
  end
  begin
    Gem::Version.create(version.dup)
  rescue ArgumentError
    raise "Invalid version specified in `VERSION=#{version}'"
  end
end

# Performs an in place, per line edit of the file indicated by _path_ by calling
# the sub method on each line and passing _pattern_, _replacement_, and _b_ as
# arguments.
def file_sub(path, pattern, replacement = nil, &b)
  tmp_path = "#{path}.tmp"
  File.open(path) do |infile|
    File.open(tmp_path, 'w') do |outfile|
      infile.each do |line|
        outfile.write(line.sub(pattern, replacement, &b))
      end
    end
  end
  File.rename(tmp_path, path)
end

# Updates the version string in the gemspec file and a version.rb file it to the
# string in _version_.
def set_version(version)
  file_sub(GEMSPEC, /(\.version\s*=\s*).*/, "\\1'#{version}'")
end

# Returns a string that is line wrapped at word boundaries, where each line is
# no longer than _line_width_ characters.
#
# This is mostly lifted directly from ActionView::Helpers::TextHelper.
def word_wrap(text, line_width = 80)
  text.split("\n").collect do |line|
    line.length > line_width ?
      line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip :
      line
  end * "\n"
end

desc 'Alias for build:gem'
task :build => 'build:gem'

# Build related tasks.
namespace :build do
  # Ensure that the manifest is consulted when building the gem.  Any
  # generated/compiled files should be available at that time.
  task :gem => :check_manifest

  # Create the gem and package tasks.
  Gem::PackageTask.new(SPEC).define

  desc 'Verify the manifest'
  task :check_manifest do
    manifest_files = (SPEC.files + SPEC.test_files).sort.uniq
    pkg_files = PKG_FILES.sort.uniq
    if manifest_files != pkg_files then
      extraneous_files = manifest_files - pkg_files
      missing_files = pkg_files - manifest_files
      message = ['The manifest does not match the automatic file list.']
      unless extraneous_files.empty? then
        message << "  Extraneous files:\n    " + extraneous_files.join("\n    ")
      end
      unless missing_files.empty?
        message << "  Missing files:\n    " + missing_files.join("\n    ")
      end
      raise message.join("\n")
    end
  end

  # Creates the README.md file from a template, the license file and the gemspec
  # contents.
  file 'README.md' => ['README.md.erb', 'LICENSE', GEMSPEC] do
    File.open('README.md', 'w') do |readme|
      readme.write(
        ERB.new(File.read('README.md.erb'), trim_mode: '-')
        .result_with_hash(spec: SPEC)
      )
    end
  end
end

# Ensure that the clobber task also clobbers package files.
task :clobber => 'build:clobber_package'

# Create the documentation task.
YARD::Rake::YardocTask.new
# Ensure that the README file is (re)generated first.
task :yard => 'README.md'

# Gem related tasks.
namespace :gem do
  desc 'Alias for build:gem'
  task :build => 'build:gem'

  desc 'Publish the gemfile'
  task :publish => ['version:check', :test, 'repo:tag', :build] do
    sh "gem push pkg/#{SPEC.name}-#{SPEC.version}*.gem"
  end
end

Rake::TestTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.ruby_opts = %w{-r ./spec/coverage}
end

# Version string management tasks.
namespace :version do
  desc 'Set the version for the project to a specified version'
  task :set do
    set_version(get_version_argument)
  end

  desc 'Set the version for the project back to 0.0.0'
  task :reset do
    set_version('0.0.0')
  end

  desc 'Check that all version strings are correctly set'
  task :check => ['version:check:spec', 'version:check:news']

  namespace :check do
    desc 'Check that the version in the gemspec is correctly set'
    task :spec do
      version = get_version_argument
      if version != SPEC.version
        raise "The given version `#{version}' does not match the gemspec version `#{SPEC.version}'"
      end
    end

    desc 'Check that the NEWS.md file mentions the version'
    task :news do
      version = get_version_argument
      begin
        File.open('NEWS.md') do |news|
          unless news.each_line.any? {|l| l =~ /^## v#{Regexp.escape(version.to_s)} /}
            raise "The NEWS.md file does not mention version `#{version}'"
          end
        end
      rescue Errno::ENOENT
        raise 'No NEWS.md file found'
      end
    end
  end
end

# Repository and workspace management tasks.
namespace :repo do
  desc 'Tag the current HEAD with the version string'
  task :tag => :check_workspace do
    version = get_version_argument
    sh "git tag -s -m 'Release v#{version}' v#{version}"
  end

  desc 'Ensure the workspace is fully committed and clean'
  task :check_workspace => ['README.md'] do
    unless `git status --untracked-files=all --porcelain`.empty?
      raise 'Workspace has been modified.  Commit pending changes and try again.'
    end
  end
end
