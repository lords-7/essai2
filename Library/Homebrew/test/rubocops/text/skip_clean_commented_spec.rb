# frozen_string_literal: true

require "rubocops/lines"

RSpec.describe RuboCop::Cop::FormulaAudit::SkipCleanCommented do
  subject(:cop) { described_class.new }

  context "when auditing formulae in homebrew-core" do
    it "reports an offense when skip_clean does not have a comment" do
      expect_offense(<<~RUBY, "/homebrew-core/")
        class Foo < Formula
          url 'https://brew.sh/foo-1.0.tgz'

          skip_clean "bin"
          ^^^^^^^^^^^^^^^^ FormulaAudit/SkipCleanCommented: Formulae in homebrew/core should document why `skip_clean` is needed with a comment.
        end
      RUBY
    end

    it "reports a single offense for multiple skip_clean lines" do
      expect_offense(<<~RUBY, "/homebrew-core/")
        class Foo < Formula
          url 'https://brew.sh/foo-1.0.tgz'

          skip_clean "bin"
          ^^^^^^^^^^^^^^^^ FormulaAudit/SkipCleanCommented: Formulae in homebrew/core should document why `skip_clean` is needed with a comment.
          skip_clean "libexec/bin"
        end
      RUBY
    end

    it "does not report an offense for a comment" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/")
        class Foo < Formula
          # some reason
          skip_clean "bin"
        end
      RUBY
    end

    it "does not report an offense for an inline comment" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/")
        class Foo < Formula
          skip_clean "bin" # some reason
        end
      RUBY
    end

    it "does not report an offense for a comment above multiple skip_clean lines" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/")
        class Foo < Formula
          # some reason
          skip_clean "bin"
          skip_clean "libexec/bin"
        end
      RUBY
    end
  end

  context "when auditing formulae not in homebrew-core" do
    it "does not report an offense" do
      expect_no_offenses(<<~RUBY)
        class Foo < Formula
          skip_clean "bin"
        end
      RUBY
    end
  end
end
