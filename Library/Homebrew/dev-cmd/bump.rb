# typed: true
# frozen_string_literal: true

require "cli/parser"
require "livecheck/livecheck"
require "dev-cmd/bump-cask-pr"

module Homebrew
  module_function

  sig { returns(CLI::Parser) }
  def bump_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Display out-of-date brew formulae and the latest version available. If the
        returned current and livecheck versions differ or when querying specific
        formulae, also displays whether a pull request has been opened with the URL.
      EOS
      switch "--full-name",
             description: "Print formulae/casks with fully-qualified names."
      switch "--no-pull-requests",
             description: "Do not retrieve pull requests from GitHub."
      switch "--formula", "--formulae",
             description: "Check only formulae."
      switch "--cask", "--casks",
             description: "Check only casks."
      switch "--open-pr",
             description: "Open a pull request for the new version if none have been opened yet."
      flag   "--limit=",
             description: "Limit number of package results returned."
      flag   "--start-with=",
             description: "Letter or word that the list of package results should alphabetically follow."
      switch "-f", "--force",
             description: "Ignore duplicate open PRs.",
             hidden:      true

      conflicts "--cask", "--formula"
      conflicts "--no-pull-requests", "--open-pr"

      named_args [:formula, :cask], without_api: true
    end
  end

  def bump
    args = bump_args.parse

    if args.limit.present? && !args.formula? && !args.cask?
      raise UsageError, "`--limit` must be used with either `--formula` or `--cask`."
    end

    formulae_and_casks = if args.formula?
      args.named.to_formulae
    elsif args.cask?
      args.named.to_casks
    else
      args.named.to_formulae_and_casks
    end
    formulae_and_casks = formulae_and_casks&.sort_by do |formula_or_cask|
      formula_or_cask.respond_to?(:token) ? formula_or_cask.token : formula_or_cask.name
    end

    unless Utils::Curl.curl_supports_tls13?
      begin
        ensure_formula_installed!("curl", reason: "Repology queries") unless HOMEBREW_BREWED_CURL_PATH.exist?
      rescue FormulaUnavailableError
        opoo "A newer `curl` is required for Repology queries."
      end
    end

    if formulae_and_casks.present?
      handle_formula_and_casks(formulae_and_casks, args)
    else
      handle_api_response(args)
    end
  end

  def handle_formula_and_casks(formulae_and_casks, args)
    Livecheck.load_other_tap_strategies(formulae_and_casks)

    ambiguous_casks = []
    if !args.formula? && !args.cask?
      ambiguous_casks = formulae_and_casks
                        .group_by { |item| Livecheck.package_or_resource_name(item, full_name: true) }
                        .values
                        .select { |items| items.length > 1 }
                        .flatten
                        .select { |item| item.is_a?(Cask::Cask) }
    end

    ambiguous_names = []
    unless args.full_name?
      ambiguous_names =
        (formulae_and_casks - ambiguous_casks).group_by { |item| Livecheck.package_or_resource_name(item) }
                                              .values
                                              .select { |items| items.length > 1 }
                                              .flatten
    end

    formulae_and_casks.each_with_index do |formula_or_cask, i|
      puts if i.positive?

      use_full_name = args.full_name? || ambiguous_names.include?(formula_or_cask)
      name = Livecheck.package_or_resource_name(formula_or_cask, full_name: use_full_name)
      repository = if formula_or_cask.is_a?(Formula)
        if formula_or_cask.head_only?
          puts "Formula is HEAD-only."
          next
        end

        Repology::HOMEBREW_CORE
      else
        Repology::HOMEBREW_CASK
      end

      package_data = if formula_or_cask.is_a?(Formula) && formula_or_cask.versioned_formula?
        nil
      else
        Repology.single_package_query(name, repository: repository)
      end

      retrieve_and_display_info_and_open_pr(
        formula_or_cask,
        name,
        package_data&.values&.first,
        args:           args,
        ambiguous_cask: ambiguous_casks.include?(formula_or_cask),
      )
    end
  end

  sig { params(args: Homebrew::CLI::Args).void }
  def handle_api_response(args)
    limit = args.limit.to_i if args.limit.present?

    api_response = {}
    unless args.cask?
      api_response[:formulae] =
        Repology.parse_api_response(limit, args.start_with, repository: Repology::HOMEBREW_CORE)
    end
    unless args.formula?
      api_response[:casks] =
        Repology.parse_api_response(limit, args.start_with, repository: Repology::HOMEBREW_CASK)
    end

    api_response.each_with_index do |(package_type, outdated_packages), idx|
      repository = if package_type == :formulae
        Repology::HOMEBREW_CORE
      else
        Repology::HOMEBREW_CASK
      end
      puts if idx.positive?
      oh1 package_type.capitalize if api_response.size > 1

      outdated_packages.each_with_index do |(_name, repositories), i|
        break if limit && i >= limit

        homebrew_repo = repositories.find do |repo|
          repo["repo"] == repository
        end

        next if homebrew_repo.blank?

        formula_or_cask = begin
          if repository == Repology::HOMEBREW_CORE
            Formula[homebrew_repo["srcname"]]
          else
            Cask::CaskLoader.load(homebrew_repo["srcname"])
          end
        rescue
          next
        end
        name = Livecheck.package_or_resource_name(formula_or_cask)
        ambiguous_cask = begin
          formula_or_cask.is_a?(Cask::Cask) && !args.cask? && Formula[name]
        rescue FormulaUnavailableError
          false
        end

        puts if i.positive?
        retrieve_and_display_info_and_open_pr(
          formula_or_cask,
          name,
          repositories,
          args:           args,
          ambiguous_cask: ambiguous_cask,
        )
      end
    end
  end

  sig {
    params(formula_or_cask: T.any(Formula, Cask::Cask)).returns(T.any(Version, String))
  }
  def livecheck_result(formula_or_cask)
    name = Livecheck.package_or_resource_name(formula_or_cask)

    referenced_formula_or_cask, =
      Livecheck.resolve_livecheck_reference(formula_or_cask, full_name: false, debug: false)

    # Check skip conditions for a referenced formula/cask
    if referenced_formula_or_cask
      skip_info = Homebrew::Livecheck::SkipConditions.referenced_skip_information(
        referenced_formula_or_cask,
        name,
        full_name: false,
        verbose:   false,
      )
    end

    skip_info ||= Homebrew::Livecheck::SkipConditions.skip_information(formula_or_cask, full_name: false,
                                                                                        verbose:   false)
    if skip_info.present?
      return "#{skip_info[:status]}#{" - #{skip_info[:messages].join(", ")}" if skip_info[:messages].present?}"
    end

    version_info = Livecheck.latest_version(
      formula_or_cask,
      referenced_formula_or_cask: referenced_formula_or_cask,
      json: true, full_name: false, verbose: true, debug: false
    )
    return "unable to get versions" if version_info.blank?

    latest = version_info[:latest]

    Version.new(latest)
  rescue => e
    "error: #{e}"
  end

  sig {
    params(formula_or_cask: T.any(Formula, Cask::Cask), name: String, state: String,
           version: T.nilable(Version)).returns T.nilable(Array)
  }
  def retrieve_pull_requests(formula_or_cask, name, state:, version: nil)
    tap_remote_repo = formula_or_cask.tap&.remote_repo || formula_or_cask.tap&.full_name
    pull_requests = GitHub.fetch_pull_requests(name, tap_remote_repo, state: state, version: version)
    if pull_requests.try(:any?)
      pull_requests = pull_requests.map { |pr| "#{pr["title"]} (#{Formatter.url(pr["html_url"])})" }.join(", ")
    end

    pull_requests
  end

  sig {
    params(formula_or_cask: T.any(Formula, Cask::Cask), repositories: Array, args: T.untyped,
           name: String).returns Hash
  }
  def retrieve_versions_by_arch(formula_or_cask:, repositories:, args:, name:)
    is_formula = formula_or_cask.is_a?(Formula)
    is_cask_with_blocks = !is_formula && formula_or_cask.on_system_blocks_exist?

    if is_formula
      type = :formula
      version_name ="formula version:"
    else
      type = :cask
      version_name = "cask version:  "
    end

    old_versions = {}
    new_versions = {}

    repology_latest = if repositories.present?
      Repology.latest_version(repositories)
    else
      "not found"
    end

    arch_options = is_cask_with_blocks ? [:arm, :intel] : [:arm]
    arch_options.each do |arch|
      Homebrew::SimulateSystem.with arch: arch do
        loaded_formula_or_cask = if is_formula
          formula_or_cask
        else
          Cask::CaskLoader.load(formula_or_cask.sourcefile_path)
        end

        version_key = is_cask_with_blocks ? arch : :general
        current_version_value = if loaded_formula_or_cask.is_a?(Formula)
          loaded_formula_or_cask.stable.version
        else
          Version.new(loaded_formula_or_cask.version)
        end

        livecheck_latest = livecheck_result(loaded_formula_or_cask)

        new_version_value = if livecheck_latest.is_a?(Version) && livecheck_latest >= current_version_value
          livecheck_latest
        elsif repology_latest.is_a?(Version) &&
              repology_latest > current_version_value &&
              !loaded_formula_or_cask.livecheckable? &&
              current_version_value != "latest"
          repology_latest
        end.presence

        # Store old and new versions
        old_versions[version_key] = current_version_value
        new_versions[version_key] = new_version_value
      end
    end

    current_version = NewVersion.new(general: old_versions[:general],
                                     arm:     old_versions[:arm],
                                     intel:   old_versions[:intel])

    new_version = NewVersion.new(general: new_versions[:general],
                                 arm:     new_versions[:arm],
                                 intel:   new_versions[:intel])

    pull_request_version = if is_formula
      new_version.general.to_s unless new_version.general.blank?
    else
      new_version.arm.to_s unless new_version.arm.blank?
    end

    open_pull_requests = if !args.no_pull_requests? && (args.named.present? || new_version.present?)
      retrieve_pull_requests(formula_or_cask, name, state: "open")
    end.presence

    closed_pull_requests = if !args.no_pull_requests? && open_pull_requests.blank? && new_version.present?
      retrieve_pull_requests(formula_or_cask, name, state: "closed", version: pull_request_version)
    end.presence

    {
      type:                 type,
      has_arch_blocks:      is_cask_with_blocks,
      version_name:         version_name,
      current_version:      current_version,
      repology_version:     repology_latest,
      new_version:          new_version,
      open_pull_requests:   open_pull_requests,
      closed_pull_requests: closed_pull_requests,
    }
  end

  sig {
    params(formula_or_cask: T.any(Formula, Cask::Cask),
           name:            String,
           repositories:    Array,
           args:            T.untyped,
           ambiguous_cask:  T::Boolean).void
  }
  def retrieve_and_display_info_and_open_pr(formula_or_cask, name, repositories, args:, ambiguous_cask: false)
    version_info = retrieve_versions_by_arch(formula_or_cask: formula_or_cask,
                                             repositories:    repositories,
                                             args:            args,
                                             name:            name)
    type = version_info[:type]
    version_name = version_info[:version_name]
    current_version = version_info[:current_version]
    new_version = version_info[:new_version]
    repology_latest = version_info[:repology_version]

    open_pull_requests = version_info[:open_pull_requests].presence || "none"
    closed_pull_requests = version_info[:closed_pull_requests].presence || "none"

    repology_relevant = ["present only in Homebrew", "not found"].exclude?(repology_latest)

    # Check if all versions are equal
    versions_equal = [:arm, :intel, :general].all? do |key|
      current_version.send(key) == new_version.send(key)
    end

    title_name = ambiguous_cask ? "#{name} (cask)" : name
    title = if repology_latest == current_version || (repology_relevant == false && versions_equal)
      "#{title_name} #{Tty.green}is up to date!#{Tty.reset}"
    else
      title_name
    end

    # Conditionally format output based on type of formula_or_cask
    current_versions = if version_info[:has_arch_blocks]
      "arm: #{current_version.arm}, intel: #{current_version.intel}"
    else
      current_version.general
    end

    new_versions = if version_info[:has_arch_blocks]
      "arm: #{new_version.arm}, intel: #{new_version.intel}"
    else
      new_version.general
    end

    ohai title

    puts <<~EOS
      Current #{version_name}   #{current_versions}
      Latest livecheck version: #{new_versions}
      Latest Repology version:  #{repology_latest}
      Open pull requests:       #{open_pull_requests || "none"}
      Closed pull requests:     #{closed_pull_requests || "none"}
    EOS

    return unless args.open_pr?

    if repology_latest.is_a?(Version) &&
       repology_latest > current_version.general &&
       repology_latest > new_version.general &&
       formula_or_cask.livecheckable?
      puts "#{title_name} was not bumped to the Repology version because it's livecheckable."
      return
    end

    return if new_version.none?

    return if open_pull_requests
    return if closed_pull_requests

    version_args = if version_info[:has_arch_blocks]
      "--version-intel=#{new_version.arm} --version-arm=#{new_version.intel}"
    else
      "--version=#{new_version.general}"
    end

    system HOMEBREW_BREW_FILE, "bump-#{type}-pr", "--no-browse",
           "--message=Created by `brew bump`", version_args, name
  end
end
