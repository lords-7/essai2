# typed: strict
# frozen_string_literal: true

class LinuxRunnerSpec < T::Struct
  const :name, String
  const :runner, String
  const :container, T::Hash[Symbol, String]
  const :workdir, String
  const :timeout, Integer
  const :cleanup, T::Boolean
end
