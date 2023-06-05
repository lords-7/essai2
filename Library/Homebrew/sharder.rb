# typed: true
# frozen_string_literal: true

require "fileutils"
require "find"
require "pathname"

class Sharder
  DEFAULT_DIRECTORY = Pathname.new("Casks").freeze
  DEFAULT_MAX_FILES = 100
  FILE_SUBSET = nil

  attr_reader :directory, :file_limit, :file_subset

  def initialize(directory: DEFAULT_DIRECTORY, file_limit: DEFAULT_MAX_FILES, file_subset: FILE_SUBSET)
    @directory = directory.is_a?(Pathname) ? directory : Pathname.new(directory)
    @file_limit = file_limit.to_i
    @file_subset = file_subset
  end

  def shard
    raise "Invalid directory: #{directory}" unless directory.directory?

    files = directory.children.select(&:file?)
    subfolders = directory.children.select(&:directory?)

    should_distribute = files.size > file_limit

    files.each do |file|
      next if file_subset&.exclude?(file.basename.to_s[0].downcase)

      subdir = destination_dir(file.basename.to_s, should_distribute)
      (directory/subdir).mkpath
      move_file(file, directory/subdir/file.basename)
    end

    subfolders.each do |subfolder|
      Sharder.new(directory: subfolder, file_limit: file_limit, file_subset:
      file_subset).shard
    end
  end

  def move_file(source, destination)
    success = system("git mv '#{source}' '#{destination}' 2>/dev/null")
    FileUtils.mv(source, destination) unless success
  rescue Errno::ENOENT
    onoe "Error moving file from #{source} to #{destination}"
    raise
  end

  def shard_subfolder(subfolder)
    if (subfolder.children.size - 2) > file_limit
      self.class.new(directory: subfolder.to_s, file_limit: file_limit, file_subset: file_subset)
          .shard
      subfolder.rmtree
    end
  rescue Errno::ENOENT
    onoe "Error removing directory: #{subfolder}"
    raise
  end

  def check
    lost_files = []
    Find.find(directory.to_s) do |path|
      file = Pathname.new(path)
      next unless file.file?

      subdir = directory/destination_dir(file.basename.to_s, true)
      lost_files << file if file.dirname.realpath != subdir.realpath
    end
    lost_files
  end

  def relocate_files(lost_files)
    lost_files.each do |file|
      subdir = destination_dir(file.basename.to_s, true)
      (directory/subdir).mkpath
      move_file(file, directory/subdir/file.basename)
    end
  end

  def print_audit_results(issues)
    if issues.empty?
      puts "No issues found."
    else
      puts "Found #{issues.size} misplaced files:"
      issues.each { |file| puts file }
    end
  end

  def destination_dir(file_name, should_distribute)
    first_chars = file_name[0, 2].downcase.gsub(/[^a-z]/, "_")
    should_distribute ? File.join(first_chars[0], first_chars) : first_chars[0]
  end
end
