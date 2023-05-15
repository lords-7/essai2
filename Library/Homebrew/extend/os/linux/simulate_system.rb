# typed: true
# frozen_string_literal: true

module Homebrew
  class SimulateSystem
    class << self
      undef current_os

      sig { returns(Symbol) }
      def current_os
        if (os = self.os)
          return os
        end

        return :macos if Homebrew::EnvConfig.simulate_macos_on_linux?

        :linux
      end
    end
  end
end
