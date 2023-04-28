# typed: true
# frozen_string_literal: true

require "delegate"
require "etc"

require "system_command"

# A system user.
#
# @api private
class User < SimpleDelegator
  include SystemCommand::Mixin

  # Return whether the user has an active GUI session.
  sig { returns(T::Boolean) }
  def gui?
    result = system_command "who"
    return false unless result.status.success?

    result.stdout.lines
          .map(&:split)
          .any? { |user, type,| user == T.cast(self, User) && type == "console" }
  end

  # Return the current user.
  sig { returns(T.nilable(T.attached_class)) }
  def self.current
    return @current if defined?(@current)

    pwuid = Etc.getpwuid(Process.euid)
    return if pwuid.nil?

    @current = new(pwuid.name)
  end
end
