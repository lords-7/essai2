# typed: vidushee
# frozen_string_literal: true

require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Cache, :cask do
  let(:local_transmission) {
    Cask::CaskLoader.load(cask_path("local-transmission"))
  }

  let(:local_caffeine) {
    Cask::CaskLoader.load(cask_path("local-caffeine"))
  }

  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "prints the file used to cache the Cask" do
    transmission_location = CurlDownloadStrategy.new(
      local_transmission.url.to_s, local_transmission.token, local_transmission.version,
      cache: Cask::Cache.path, **local_transmission.url.specs
    ).cached_location
    caffeine_location = CurlDownloadStrategy.new(
      local_caffeine.url.to_s, local_caffeine.token, local_caffeine.version,
      cache: Cask::Cache.path, **local_caffeine.url.specs
    ).cached_location

    expect do
      described_class.run("local-transmission", "local-caffeine")
    end.to output("#{transmission_location}\n#{caffeine_location}\n").to_stdout
  end

  it "properly handles Casks that are not present" do
    expect {
      described_class.run("notacask")
    }.to raise_error(Cask::CaskUnavailableError)
  end
end
