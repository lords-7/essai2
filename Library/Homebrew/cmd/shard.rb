# typed: true
# frozen_string_literal: true

require "sharder"
require "cli/parser"

module Homebrew
  sig { returns(CLI::Parser) }
  def self.shard_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Distribute files in a directory into multiple subdirectories, where the
        directory is specified as a command-line argument.
      EOS
      flag "--directory=",
           description: "Specify the starting directory"
      flag "--file_limit=",
           description: "Specify the maximum number of files per-directory before sharding."
      flag "--file_subset=",
           description: "Limit to a subset of files based on initial letter."
      switch "--check",
             description: "Audit the directory for sharding."
      switch "--fix",
             description: "Fix issues found during the audit."
    end
  end

  def self.shard
    args = shard_args.parse

    sharder = Sharder.new(
      directory:   args.directory || Sharder::DEFAULT_DIRECTORY,
      file_limit:  args.file_limit || Sharder::DEFAULT_MAX_FILES,
      file_subset: args.file_subset || Sharder::FILE_SUBSET,
    )

    if args.check?
      lost_files = sharder.check
      if args.fix?
        sharder.relocate_files(lost_files)
      else
        sharder.print_audit_results(lost_files)
      end
    else
      sharder.shard
    end
  end
end
