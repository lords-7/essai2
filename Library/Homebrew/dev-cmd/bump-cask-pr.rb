# typed: true
# frozen_string_literal: true

require "cask"
require "cask/download"
require "cli/parser"
require "utils/tar"

module Homebrew
  module_function

  class NewVersion < T::Struct
    prop :general, T.nilable(String)
    prop :arm, T.nilable(String)
    prop :intel, T.nilable(String)

    def initialize(general: @general, arm: @arm, intel: @intel)
      super
      @general = parse_new_version(general) unless general.nil?
      @intel = parse_new_version(intel) unless intel.nil?
      @arm = parse_new_version(arm) unless arm.nil?

      if general.nil?
        raise UsageError, "`--version-intel` must not be empty." if intel.nil?
        raise UsageError, "`--version-arm` must not be empty." if arm.nil?
      elsif general && (arm || intel)
        raise UsageError, "You cannot specify --version with --version-intel and --version-arm."
      end
    end

    def parse_new_version(version)
      if %w[latest :latest].include?(version)
        "latest"
      else
        Cask::DSL::Version.new(version)
      end
    end

    def empty?
      @general.nil? && @arm.nil? && @intel.nil?
    end
  end

  sig { returns(CLI::Parser) }
  def bump_cask_pr_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Create a pull request to update <cask> with a new version.

        A best effort to determine the <SHA-256> will be made if the value is not
        supplied by the user.
      EOS
      switch "-n", "--dry-run",
             description: "Print what would be done rather than doing it."
      switch "--write-only",
             description: "Make the expected file modifications without taking any Git actions."
      switch "--commit",
             depends_on:  "--write-only",
             description: "When passed with `--write-only`, generate a new commit after writing changes " \
                          "to the cask file."
      switch "--no-audit",
             description: "Don't run `brew audit` before opening the PR."
      switch "--online",
             description: "Run `brew audit --online` before opening the PR."
      switch "--no-style",
             description: "Don't run `brew style --fix` before opening the PR."
      switch "--no-browse",
             description: "Print the pull request URL instead of opening in a browser."
      switch "--no-fork",
             description: "Don't try to fork the repository."
      flag "--version=",
           description: "Specify the new <version> for the cask."
      flag "--version-intel=",
           description: "Specify the new cask <version> for the Intel architecture."
      flag "--version-arm=",
           description: "Specify the new cask <version> for the ARM architecture."
      flag "--message=",
           description: "Prepend <message> to the default pull request message."
      flag "--url=",
           description: "Specify the <URL> for the new download."
      flag "--sha256=",
           description: "Specify the <SHA-256> checksum of the new download."
      flag "--fork-org=",
           description: "Use the specified GitHub organization for forking."
      switch "-f", "--force",
             description: "Ignore duplicate open PRs."

      conflicts "--dry-run", "--write"
      conflicts "--version=", "--version-intel="
      conflicts "--version=", "--version-arm="
      conflicts "--no-audit", "--online"

      named_args :cask, number: 1, without_api: true
    end
  end

  def bump_cask_pr
    args = bump_cask_pr_args.parse
    # This will be run by `brew style` later so run it first to not start
    # spamming during normal output.
    Homebrew.install_bundler_gems!

    # As this command is simplifying user-run commands then let's just use a
    # user path, too.
    ENV["PATH"] = PATH.new(ORIGINAL_PATHS).to_s

    # Use the user's browser, too.
    ENV["BROWSER"] = Homebrew::EnvConfig.browser

    cask = args.named.to_casks.first

    odie "This cask is not in a tap!" if cask.tap.blank?
    odie "This cask's tap is not a Git repository!" unless cask.tap.git?

    new_version = Homebrew::NewVersion.new(
      general: args.version,
      intel:   args.version_intel,
      arm:     args.version_arm,
    )

    new_hash = args.sha256
    if new_hash.present?
      raise UsageError, "`--sha256` must not be empty." if new_hash.blank?

      new_hash = :no_check if %w[no_check :no_check].include?(new_hash)
    end

    new_base_url = unless (new_base_url = args.url).nil?
      raise UsageError, "`--url` must not be empty." if new_base_url.blank?

      begin
        URI(new_base_url)
      rescue URI::InvalidURIError
        raise UsageError, "`--url` is not valid."
      end
    end

    if new_version.empty? && new_base_url.nil? && new_hash.nil?
      raise UsageError, "No `--version`, `--url` or `--sha256` argument specified!"
    end

    check_pull_requests(cask, state: "open", args: args)
    # if we haven't already found open requests, try for an exact match across closed requests
    if new_version.general.present?
      check_pull_requests(cask, state: "closed", args: args, version: new_version.general)
    else
      check_pull_requests(cask, state: "closed", args: args, version: new_version.arm)
      check_pull_requests(cask, state: "closed", args: args, version: new_version.intel)
    end

    replacement_pairs ||= []
    branch_name = "bump-#{cask.token}"
    commit_message = nil

    if new_version.general.nil? || (new_version.arm.nil? && new_version.intel.nil?)
      # For simplicity, our naming defers to the arm version if we multiple architectures are specified
      branch_version = new_version.arm || new_version.general
      commit_version = if branch_version.before_comma == cask.version.before_comma
        branch_version
      else
        branch_version.before_comma
      end
      branch_name = "bump-#{cask.token}-#{branch_version.tr(",:", "-")}"
      commit_message ||= "#{cask.token} #{commit_version}"

      OnSystem::ARCH_OPTIONS.each do |arch|
        SimulateSystem.with arch: arch do
          old_cask = Cask::CaskLoader.load(cask.sourcefile_path)
          old_version  = old_cask.version
          bump_version = new_version.send(arch) || new_version.general

          old_version_regex = old_version.latest? ? ":latest" : %Q(["']#{Regexp.escape(old_version.to_s)}["'])
          replacement_pairs << [/version\s+#{old_version_regex}/m,
                                "version #{bump_version.latest? ? ":latest" : %Q("#{bump_version}")}"]

          # We are replacing our version here so we can get the new hash
          tmp_contents = Utils::Inreplace.inreplace_pairs(cask.sourcefile_path,
                                                          replacement_pairs.uniq.compact,
                                                          read_only_run: true,
                                                          silent:        true)

          tmp_cask = Cask::CaskLoader.load(tmp_contents)
          updated_version = tmp_cask.version
          old_hash = tmp_cask.sha256
          if updated_version.latest? || new_hash == :no_check
            opoo "Ignoring specified `--sha256=` argument." if new_hash.is_a?(String)
            replacement_pairs << [/"#{old_hash}"/, ":no_check"] if old_hash != :no_check
          elsif old_hash == :no_check && new_hash != :no_check
            replacement_pairs << %W[:no_check "#{new_hash}"] if new_hash.is_a?(String)
          elsif old_hash != :no_check
            if new_hash.nil? || cask.languages.present?
              if new_hash && cask.languages.present?
                opoo "Multiple checksum replacements required; ignoring specified `--sha256` argument."
              end
              # TODO: Ensure this works as expected for casks with multiple languages
              languages = cask.languages
              languages = [nil] if languages.empty?
              languages.each do |language|
                tmp_cask = if language.blank?
                  tmp_cask
                else
                  tmp_cask.merge(Cask::Config.new(explicit: { languages: [language] }))
                end

                cask_download = Cask::Download.new(tmp_cask, quarantine: true)
                download      = cask_download.fetch(verify_download_integrity: false)
                Utils::Tar.validate_file(download)
                replacement_pairs << [tmp_cask.sha256.to_s, download.sha256]
              end
            end
          elsif new_hash
            opoo "Cask contains multiple hashes; only updating hash for current arch." if cask.on_system_blocks_exist?
            replacement_pairs << [old_hash.to_s, new_hash]
          end
        end
      end
    end
    # Now that we have all replacement pairs, we will replace them further down

    old_contents = File.read(cask.sourcefile_path)

    if new_base_url
      commit_message ||= "#{cask.token}: update URL"

      m = /^ +url "(.+?)"\n/m.match(old_contents)
      odie "Could not find old URL in cask!" if m.nil?

      old_base_url = m.captures.fetch(0)

      replacement_pairs << [
        /#{Regexp.escape(old_base_url)}/,
        new_base_url.to_s,
      ]
    end

    commit_message ||= "#{cask.token}: update checksum" if new_hash

    Utils::Inreplace.inreplace_pairs(cask.sourcefile_path,
                                     replacement_pairs.uniq.compact,
                                     read_only_run: args.dry_run?,
                                     silent:        args.quiet?)

    run_cask_audit(cask, old_contents, args: args)
    run_cask_style(cask, old_contents, args: args)

    pr_info = {
      branch_name:     branch_name,
      commit_message:  commit_message,
      old_contents:    old_contents,
      pr_message:      "Created with `brew bump-cask-pr`.",
      sourcefile_path: cask.sourcefile_path,
      tap:             cask.tap,
    }
    GitHub.create_bump_pr(pr_info, args: args)
  end

  def check_pull_requests(cask, state:, args:, version: nil)
    tap_remote_repo = cask.tap.full_name || cask.tap.remote_repo

    GitHub.check_for_duplicate_pull_requests(
      cask.token,
      tap_remote_repo,
      state:   state,
      version: version,
      file:    cask.sourcefile_path.relative_path_from(cask.tap.path).to_s,
      args:    args,
    )
  end

  def run_cask_audit(cask, old_contents, args:)
    if args.dry_run?
      if args.no_audit?
        ohai "Skipping `brew audit`"
      elsif args.online?
        ohai "brew audit --cask --online #{cask.full_name}"
      else
        ohai "brew audit --cask #{cask.full_name}"
      end
      return
    end
    failed_audit = false
    if args.no_audit?
      ohai "Skipping `brew audit`"
    elsif args.online?
      system HOMEBREW_BREW_FILE, "audit", "--cask", "--online", cask.full_name
      failed_audit = !$CHILD_STATUS.success?
    else
      system HOMEBREW_BREW_FILE, "audit", "--cask", cask.full_name
      failed_audit = !$CHILD_STATUS.success?
    end
    return unless failed_audit

    cask.sourcefile_path.atomic_write(old_contents)
    odie "`brew audit` failed!"
  end

  def run_cask_style(cask, old_contents, args:)
    if args.dry_run?
      if args.no_style?
        ohai "Skipping `brew style --fix`"
      else
        ohai "brew style --fix #{cask.sourcefile_path.basename}"
      end
      return
    end
    failed_style = false
    if args.no_style?
      ohai "Skipping `brew style --fix`"
    else
      system HOMEBREW_BREW_FILE, "style", "--fix", cask.sourcefile_path
      failed_style = !$CHILD_STATUS.success?
    end
    return unless failed_style

    cask.sourcefile_path.atomic_write(old_contents)
    odie "`brew style --fix` failed!"
  end
end
