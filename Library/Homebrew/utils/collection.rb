# typed: true
# frozen_string_literal: true

module Utils
  module Collection
    def self.recursive_compact(value)
      case value
      when Array
        recursive_compact_array(value)
      when Hash
        recursive_compact_hash(value)
      else
        value
      end
    end

    sig { params(array: Array).returns(T.nilable(Array)) }
    def self.recursive_compact_array(array)
      array.map do |value|
        recursive_compact(value)
      end.compact.presence
    end

    sig { params(hash: Hash).returns(T.nilable(Hash)) }
    def self.recursive_compact_hash(hash)
      hash.transform_values do |value|
        recursive_compact(value)
      end.compact.presence
    end
  end
end
