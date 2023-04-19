# typed: false
# frozen_string_literal: true

require "language/python"
require "utils/shebang"

describe Language::Python::Shebang do
  let(:file) { File.open("#{TEST_TMPDIR}/python-shebang", "w") }
  let(:python_f) do
    formula "python@3.11" do
      url "https://brew.sh/python-1.0.tgz"
    end
  end

  before do
    file.write <<~EOS
      #!/usr/bin/python2
      a
      b
      c
    EOS
    file.flush
  end

  after { FileUtils.rm file }

  describe "#detected_python_shebang" do
    it "can be used to replace Python shebangs" do
      allow(Formulary).to receive(:factory).with(python_f.name).and_return(python_f)
      formula "foo" do
        include Language::Python::Shebang # rubocop:disable RSpec/DescribedClass (does not resolve in this context)
        url "https://brew.sh/foo-1.0.tgz"

        depends_on "python@3.11"
        def install
          rewrite_shebang detected_python_shebang(use_python_from_path: false),
                          Pathname("#{TEST_TMPDIR}/python-shebang")
        end
      end.install

      expect(File.read(file)).to eq <<~EOS
        #!#{HOMEBREW_PREFIX}/opt/python@3.11/bin/python3.11
        a
        b
        c
      EOS
    end

    it "can be pointed to a `python3` in PATH" do
      formula "foo" do
        include Language::Python::Shebang # rubocop:disable RSpec/DescribedClass (does not resolve in this context)
        url "https://brew.sh/foo-1.0.tgz"

        depends_on "python@3.11"
        def install
          rewrite_shebang detected_python_shebang(use_python_from_path: true),
                          Pathname("#{TEST_TMPDIR}/python-shebang")
        end
      end.install

      expect(File.read(file)).to eq <<~EOS
        #!/usr/bin/env python3
        a
        b
        c
      EOS
    end
  end
end
