# typed: true
# frozen_string_literal: true

module Cask
  module Artifact
    # Artifact corresponding to the `binary` stanza.
    #
    # @api private
    class Binary < Symlinked
      def link(command: nil, **options)
        super(command: command, **options)
        return if source.executable?

        if source.writable?
          FileUtils.chmod "+x", source
        else
          command.run!("/bin/chmod", args: ["+x", source], sudo: true)
        end
      end
    end
  end
end
