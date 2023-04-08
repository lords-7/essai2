# typed: false
# frozen_string_literal: true

module Test
  module Helper
    module Cask
      def stub_cask_loader(cask, ref = cask.token, call_original: false)
        allow(::Cask::CaskLoader).to receive(:for).and_call_original if call_original

        loader = ::Cask::CaskLoader::FromInstanceLoader.new cask
        allow(::Cask::CaskLoader).to receive(:for).with(ref).and_return(loader)
      end
    end
  end
end
