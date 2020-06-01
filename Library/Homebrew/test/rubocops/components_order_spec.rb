# typed: false
# frozen_string_literal: true

require "rubocops/components_order"

describe RuboCop::Cop::FormulaAudit::ComponentsOrder do
  subject(:cop) { described_class.new }

  context "When auditing formula components order" do
    it "When uses_from_macos precedes depends_on" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          homepage "https://brew.sh"
          url "https://brew.sh/foo-1.0.tgz"

          uses_from_macos "apple"
          depends_on "foo"
          ^^^^^^^^^^^^^^^^ `depends_on` (line 6) should be put before `uses_from_macos` (line 5)
        end
      RUBY
    end

    it "When `bottle` precedes `livecheck`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          homepage "https://brew.sh"
          url "https://brew.sh/foo-1.0.tgz"

          bottle :unneeded

          livecheck do
          ^^^^^^^^^^^^ `livecheck` (line 7) should be put before `bottle` (line 5)
            url "https://brew.sh/foo/versions/"
            regex(/href=.+?foo-(\d+(?:\.\d+)+)\.t/)
          end
        end
      RUBY
    end

    it "When url precedes homepage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://brew.sh/foo-1.0.tgz"
          homepage "https://brew.sh"
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ `homepage` (line 3) should be put before `url` (line 2)
        end
      RUBY
    end

    it "When `resource` precedes `depends_on`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://brew.sh/foo-1.0.tgz"

          resource "foo2" do
            url "https://brew.sh/foo-2.0.tgz"
          end

          depends_on "openssl"
          ^^^^^^^^^^^^^^^^^^^^ `depends_on` (line 8) should be put before `resource` (line 4)
        end
      RUBY
    end

    it "When `test` precedes `plist`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url "https://brew.sh/foo-1.0.tgz"

          test do
            expect(shell_output("./dogs")).to match("Dogs are terrific")
          end

          def plist
          ^^^^^^^^^ `plist` (line 8) should be put before `test` (line 4)
          end
        end
      RUBY
    end

    it "When only one of many `depends_on` precedes `conflicts_with`" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          depends_on "autoconf" => :build
          conflicts_with "visionmedia-watch"
          depends_on "automake" => :build
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `depends_on` (line 4) should be put before `conflicts_with` (line 3)
          depends_on "libtool" => :build
          depends_on "pkg-config" => :build
          depends_on "gettext"
        end
      RUBY
    end
  end

  context "When auditing formula components order with autocorrect" do
    it "When url precedes homepage" do
      source = <<~RUBY
        class Foo < Formula
          url "https://brew.sh/foo-1.0.tgz"
          homepage "https://brew.sh"
        end
      RUBY

      correct_source = <<~RUBY
        class Foo < Formula
          homepage "https://brew.sh"
          url "https://brew.sh/foo-1.0.tgz"
        end
      RUBY

      corrected_source = autocorrect_source(source)
      expect(corrected_source).to eq(correct_source)
    end

    it "When `resource` precedes `depends_on`" do
      source = <<~RUBY
        class Foo < Formula
          url "https://brew.sh/foo-1.0.tgz"

          resource "foo2" do
            url "https://brew.sh/foo-2.0.tgz"
          end

          depends_on "openssl"
        end
      RUBY

      correct_source = <<~RUBY
        class Foo < Formula
          url "https://brew.sh/foo-1.0.tgz"

          depends_on "openssl"

          resource "foo2" do
            url "https://brew.sh/foo-2.0.tgz"
          end
        end
      RUBY

      corrected_source = autocorrect_source(source)
      expect(corrected_source).to eq(correct_source)
    end
  end
end
