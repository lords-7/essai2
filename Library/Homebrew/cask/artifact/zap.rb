# typed: true
# frozen_string_literal: true

require "cask/artifact/abstract_uninstall"

module Cask
  module Artifact
    # Artifact corresponding to the `zap` stanza.
    #
    # @api private
    class Zap < AbstractUninstall
      def uninstall_phase(**options)
        ORDERED_DIRECTIVES.reject { |directive_sym| directive_sym == :rmdir }
                          .each do |directive_sym|
          dispatch_uninstall_directive(directive_sym, **options)
        end
      end

      def post_uninstall_phase(**options)
        dispatch_uninstall_directive(:rmdir, **options)
      end

      def zap_phase(**options)
        uninstall_phase(**options)
        post_uninstall_phase(**options)
      end
    end
  end
end
