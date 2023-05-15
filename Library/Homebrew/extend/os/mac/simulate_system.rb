# typed: true
# frozen_string_literal: true

module Homebrew
  class SimulateSystem
    class << self
      undef current_os

      sig { returns(Symbol) }
      def current_os
        os || MacOS.version.to_sym
      end
    end
  end
end
