# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/bump-cask-pr"

describe "brew bump-cask-pr" do
  it_behaves_like "parseable arguments"
  describe Homebrew::NewVersion do
    let(:general_version) { "1.2.3" }
    let(:intel_version) { "2.3.4" }
    let(:arm_version) { "3.4.5" }

    describe "#initialize" do
      context "when only the general version is provided" do
        it "parses the version and not raise an error" do
          expect { described_class.new(general: general_version) }.not_to raise_error
        end
      end

      context "when only the intel version is provided" do
        it "raises a UsageError" do
          expect do
            described_class.new(intel: intel_version)
          end.to raise_error(UsageError,
                             "Invalid usage: `--version-arm` must not be empty.")
        end
      end

      context "when only the arm version is provided" do
        it "raises a UsageError" do
          expect do
            described_class.new(arm: arm_version)
          end.to raise_error(UsageError,
                             "Invalid usage: `--version-intel` must not be empty.")
        end
      end

      context "when the general version and intel version are both provided" do
        it "raises a UsageError" do
          expect { described_class.new(general: general_version, intel: intel_version) }
            .to raise_error(UsageError,
                            "Invalid usage: You cannot specify --version with --version-intel and --version-arm.")
        end
      end

      context "when all versions are provided" do
        it "raises a UsageError" do
          expect { described_class.new(general: general_version, intel: intel_version, arm: arm_version) }
            .to raise_error(UsageError,
                            "Invalid usage: You cannot specify --version with --version-intel and --version-arm.")
        end
      end
    end

    describe "#parse_new_version" do
      context "when the version is latest" do
        it "returns a version object for latest" do
          new_version = described_class.new(general: "latest")
          expect(new_version.general.to_s).to eq("latest")
        end
      end

      context "when the version is not latest" do
        it "returns a version object for the given version" do
          new_version = described_class.new(general: general_version)
          expect(new_version.general.to_s).to eq(general_version)
        end
      end
    end

    describe "#blank?" do
      context "when a version is given" do
        it "returns false" do
          new_version = described_class.new(general: general_version)
          expect(new_version.blank?).to be false
        end
      end
    end
  end
end
