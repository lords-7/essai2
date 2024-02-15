# frozen_string_literal: true

require "extend/cached"

RSpec.describe Cached do
  subject(:counter) { klass.new }

  let(:klass) do
    Class.new do
      extend Cached
      include Cached::Clear

      def initialize
        @number = 0
      end

      cached def increment
        @number += 1
      end
    end
  end

  describe "#cached" do
    it "caches a method" do
      expect(counter.increment).to eq 1
      expect(counter.increment).to eq 1
    end
  end

  describe Cached::Clear do
    describe "#clear_cache" do
      it "clears the cache" do
        expect(counter.increment).to eq 1
        expect(counter.increment).to eq 1
        counter.clear_cache
        expect(counter.increment).to eq 2
        expect(counter.increment).to eq 2
        counter.clear_cache
        expect(counter.increment).to eq 3
        expect(counter.increment).to eq 3
      end
    end
  end
end
