# typed: strict
# frozen_string_literal: true

class MacOSRunnerSpec < T::Struct
  const :name, String
  const :runner, String
  const :timeout, Integer
  const :cleanup, T::Boolean
end
