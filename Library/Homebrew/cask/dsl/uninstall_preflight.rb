# typed: strict
# frozen_string_literal: true

module Cask
  class DSL
    # Class corresponding to the `uninstall_preflight` stanza.
    #
    # @api private
    class UninstallPreflight < Base
      include Staged
    end
  end
end
