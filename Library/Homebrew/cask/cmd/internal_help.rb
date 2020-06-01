# typed: vidushee
# frozen_string_literal: true

module Cask
  class Cmd
    class InternalHelp < AbstractInternalCommand
      def initialize(*)
        super
        return if args.empty?

        raise ArgumentError, "#{self.class.command_name} does not take arguments."
      end

      def run
        max_command_len = Cmd.commands.map(&:length).max
        puts "Unstable Internal-use Commands:\n\n"
        Cmd.command_classes.each do |klass|
          next if klass.visible?

          puts "    #{klass.command_name.ljust(max_command_len)}  #{klass.help}"
        end
        puts "\n"
      end

      def self.help
        "print help strings for unstable internal-use commands"
      end
    end
  end
end
