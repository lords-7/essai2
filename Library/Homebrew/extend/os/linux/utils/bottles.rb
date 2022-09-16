# typed: true
# frozen_string_literal: true

module Utils
  module Bottles
    class << self
      alias generic_tag tag
      undef tag

      def tag(symbol = nil)
        return super(symbol) if symbol.present?

        OS::LINUX_CI_OS_VERSION.downcase.delete(" .")
      end
    end

    class Collector
      private

      alias generic_find_matching_tag find_matching_tag

      def find_matching_tag(tag, no_older_versions: false)
        # Used primarily by developers newer Linux bottles.
        if no_older_versions ||
           (Homebrew::EnvConfig.developer? &&
            Homebrew::EnvConfig.skip_or_later_bottles?)
          generic_find_matching_tag(tag)
        else
          generic_find_matching_tag(tag) ||
            generic_find_matching_tag(generic_tag)
        end
      end
    end
  end
end
