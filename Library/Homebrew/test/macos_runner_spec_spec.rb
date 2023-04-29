# frozen_string_literal: true

require "macos_runner_spec"

describe MacOSRunnerSpec do
  let(:spec) { described_class.new(name: "macOS 11-arm64", runner: "11-arm64", timeout: 90, cleanup: true) }

  it "has immutable attributes" do
    [:name, :runner, :timeout, :cleanup].each do |attribute|
      expect(spec.respond_to?("#{attribute}=")).to be(false)
    end
  end
end
