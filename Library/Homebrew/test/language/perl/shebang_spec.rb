# typed: false
# frozen_string_literal: true

require "language/perl"
require "utils/shebang"

describe Language::Perl::Shebang do
  let(:file) { File.open("#{TEST_TMPDIR}/perl-shebang", "w") }
  let(:perl_f) do
    formula "perl" do
      url "https://brew.sh/perl-1.0.tgz"
    end
  end

  before do
    file.write <<~EOS
      #!/usr/bin/env perl
      a
      b
      c
    EOS
    file.flush
  end

  after { FileUtils.rm file }

  describe "#detected_perl_shebang" do
    it "can be used to replace Perl shebangs" do
      allow(Formulary).to receive(:factory).with(perl_f.name).and_return(perl_f)
      formula "foo" do
        include Language::Perl::Shebang # rubocop:disable RSpec/DescribedClass (does not resolve in this context)
        url "https://brew.sh/foo-1.0.tgz"
        uses_from_macos "perl"

        def install
          rewrite_shebang detected_perl_shebang, Pathname("#{TEST_TMPDIR}/perl-shebang")
        end
      end.install

      expected_shebang = if OS.mac?
        "/usr/bin/perl#{MacOS.preferred_perl_version}"
      else
        HOMEBREW_PREFIX/"opt/perl/bin/perl"
      end

      expect(File.read(file)).to eq <<~EOS
        #!#{expected_shebang}
        a
        b
        c
      EOS
    end
  end
end
