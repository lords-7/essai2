# typed: strict
# frozen_string_literal: true

require "version"

class URL
  sig { returns(T::Hash[Symbol, T.untyped]) }
  attr_reader :specs

  sig { returns(T.nilable(String)) }
  attr_reader :using

  sig { params(url: String, specs: T::Hash[Symbol, T.untyped]).void }
  def initialize(url, specs = {})
    @url = T.let(url.freeze, String)
    @specs = T.let(specs.dup, T::Hash[Symbol, T.untyped])
    @using = T.let(@specs.delete(:using), T.nilable(String))
    @specs.freeze
  end

  sig { returns(String) }
  def to_s
    @url
  end

  sig { returns(T.class_of(AbstractDownloadStrategy)) }
  def download_strategy
    @download_strategy ||= T.let(DownloadStrategyDetector.detect(@url, @using), T.nilable(T.class_of(AbstractDownloadStrategy)))
  end

  sig { returns(Version) }
  def version
    @version ||= T.let(Version.detect(@url, **@specs), T.nilable(Version))
  end
end
