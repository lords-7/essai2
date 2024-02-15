# typed: strict
# frozen_string_literal: true

module Cached
  module Clear
    sig { void }
    def clear_cache
      super if defined?(super)

      return unless defined?(@cached_method_calls)

      remove_instance_variable(:@cached_method_calls)
    end
  end

  sig { params(method: Symbol).returns(Symbol) }
  def cached(method)
    uncached_instance_method = instance_method(method)

    define_method(method) do |*args, **options, &block|
      @cached_method_calls ||= T.let({}, T.nilable(T::Hash[Symbol, T::Hash[T.untyped, T.untyped]]))
      cache = @cached_method_calls[method] ||= {}

      key = [args, options, block]
      if cache.key?(key)
        cache.fetch(key)
      else
        cache[key] = uncached_instance_method.bind(self).call(*args, **options, &block)
      end
    end
  end

  sig { params(method: Symbol).returns(Symbol) }
  def cached_class_method(method)
    uncached_singleton_method = singleton_method(method)

    define_singleton_method(method) do |*args, **options, &block|
      @cached_method_calls ||= T.let({}, T.nilable(T::Hash[Symbol, T::Hash[T.untyped, T.untyped]]))
      cache = @cached_method_calls[method] ||= {}

      key = [args, options, block]
      if cache.key?(key)
        cache[key]
      else
        cache[key] = uncached_singleton_method.call(*args, **options, &block)
      end
    end
  end
end
