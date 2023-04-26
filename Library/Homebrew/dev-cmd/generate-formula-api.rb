# typed: true
# frozen_string_literal: true

require "cli/parser"
require "formula"

module Homebrew
  module_function

  sig { returns(CLI::Parser) }
  def generate_formula_api_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Generates Formula API data files for formulae.brew.sh.

        The generated files are written to the current directory.
      EOS

      named_args :none
    end
  end

  FORMULA_JSON_TEMPLATE = <<~EOS
    ---
    layout: formula_json
    ---
    {{ content }}
  EOS

  def html_template(title, aliases)
    redirect_list = ""
    aliases.each do |item|
      redirect_list += "  - /formula/#{item}\n"
    end

    <<~EOS
      ---
      title: #{title}
      layout: formula
      redirect_from:
        - /formula-linux/#{title}
      #{redirect_list}
      ---
      {{ content }}
    EOS
  end

  def generate_formula_api
    generate_formula_api_args.parse

    tap = CoreTap.instance

    directories = ["_data/formula", "api/formula", "formula"]
    FileUtils.rm_rf directories + ["_data/formula_canonical.json"]
    FileUtils.mkdir_p directories

    Formulary.enable_factory_cache!
    Formula.generating_hash!

    # invert the hash but group duplicates
    tap_renames = tap.formula_renames.each_with_object({}) { |(k, v), o| (o[v]||=[])<<k }

    tap.formula_names.each do |name|
      formula = Formulary.factory(name)
      name = formula.name
      json = JSON.pretty_generate(formula.to_hash_with_variations)

      renames = tap_renames.fetch(name, [])
      File.write("_data/formula/#{name.tr("+", "_")}.json", "#{json}\n")
      File.write("formula/#{name}.html", html_template(name, renames))
      File.write("api/formula/#{name}.json", FORMULA_JSON_TEMPLATE)
      # redirects are only supported for HTML so simply store a copy here
      renames.each do |original|
        File.write("api/formula/#{original}.json", FORMULA_JSON_TEMPLATE)
      end
    rescue
      onoe "Error while generating data for formula '#{name}'."
      raise
    end

    canonical_json = JSON.pretty_generate(tap.formula_renames.merge(tap.alias_table))
    File.write("_data/formula_canonical.json", "#{canonical_json}\n")
  end
end
