# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # `context` should not be used for specifying methods.
      #
      # @example
      #   # bad
      #   context '#foo_bar' do
      #     # ...
      #   end
      #
      #   context '.foo_bar' do
      #     # ...
      #   end
      #
      #   # good
      #   describe '#foo_bar' do
      #     # ...
      #   end
      #
      #   describe '.foo_bar' do
      #     # ...
      #   end
      class ContextMethod < Cop
        extend AutoCorrector

        MSG = 'Use `describe` for testing methods.'

        def_node_matcher :context_method, <<-PATTERN
          (block (send #{RSPEC} :context $(str #method_name?) ...) ...)
        PATTERN

        def on_block(node)
          context_method(node) do |context|
            add_offense(context) do |corrector|
              corrector.replace(node.send_node.loc.selector, 'describe')
            end
          end
        end

        private

        def method_name?(description)
          description.start_with?('.', '#')
        end
      end
    end
  end
end
