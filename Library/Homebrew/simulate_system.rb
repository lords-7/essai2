# typed: true
# frozen_string_literal: true

require "macos_version"

module Homebrew
  # Helper module for simulating different system condfigurations.
  #
  # @api private
  class SimulateSystem
    class << self
      MACOS_SYMBOLS = Set.new([:macos, *MacOSVersion::SYMBOLS.keys]).freeze
      private_constant :MACOS_SYMBOLS

      attr_reader :arch, :os

      sig {
        type_parameters(:U).params(
          os:     Symbol,
          arch:   Symbol,
          _block: T.proc.returns(T.type_parameter(:U)),
        ).returns(T.type_parameter(:U))
      }
      def with(os: T.unsafe(nil), arch: T.unsafe(nil), &_block)
        raise ArgumentError, "At least one of `os` or `arch` must be specified." if !os && !arch

        if self.os || self.arch
          raise "Cannot simulate#{os&.inspect&.prepend(" ")}#{arch&.inspect&.prepend(" ")} while already " \
                "simulating#{self.os&.inspect&.prepend(" ")}#{self.arch&.inspect&.prepend(" ")}."
        end

        begin
          self.os = os if os
          self.arch = arch if arch

          yield
        ensure
          clear
        end
      end

      sig { params(new_os: Symbol).void }
      def os=(new_os)
        raise "Unknown OS: #{new_os}" if MACOS_SYMBOLS.exclude?(new_os) && new_os != :linux

        @os = new_os
      end

      sig { params(new_arch: Symbol).void }
      def arch=(new_arch)
        raise "New arch must be :arm or :intel" unless OnSystem::ARCH_OPTIONS.include?(new_arch)

        @arch = new_arch
      end

      sig { void }
      def clear
        @os = @arch = nil
      end

      sig { returns(T::Boolean) }
      def simulating_or_running_on_macos?
        MACOS_SYMBOLS.include?(current_os)
      end

      sig { returns(T::Boolean) }
      def simulating_or_running_on_linux?
        current_os == :linux
      end

      sig { returns(Symbol) }
      def current_arch
        @arch || Hardware::CPU.type
      end

      sig { returns(Symbol) }
      def current_os
        os || :generic
      end
    end
  end
end

require "extend/os/simulate_system"
