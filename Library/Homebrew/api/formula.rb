# typed: false
# frozen_string_literal: true

module Homebrew
  module API
    # Helper functions for using the formula JSON API.
    #
    # @api private
    module Formula
      class << self
        extend T::Sig

        sig { params(name: String).returns(Hash) }
        def fetch(name)
          Homebrew::API.fetch "formula/#{name}.json"
        end

        sig { returns(Hash) }
        def all_formulae
          @all_formulae ||= begin
            target = HOMEBREW_CACHE_API/"formula.json"
            json_formulae = if Homebrew::EnvConfig.defer_api_updates?
              begin
                JSON.parse(target.read)
              rescue JSON::ParserError
                nil # fallback to force download
              end
            end
            json_formulae = Homebrew::API.fetch_json_api_file "formula.json", target: target if json_formulae.nil?

            @all_aliases = {}
            json_formulae.to_h do |json_formula|
              json_formula["aliases"].each do |alias_name|
                @all_aliases[alias_name] = json_formula["name"]
              end

              [json_formula["name"], json_formula.except("name")]
            end
          end
        end

        sig { returns(Hash) }
        def all_aliases
          all_formulae if @all_aliases.blank?

          @all_aliases
        end
      end
    end
  end
end
