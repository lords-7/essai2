describe "download strategies", :cask do
  let(:url) { "http://example.com/cask.dmg" }
  let(:url_options) { {} }
  let(:cask) {
    instance_double(Hbc::Cask, token:   "some-cask",
                               url:     Hbc::URL.new(url, url_options),
                               version: "1.2.3.4")
  }

  describe Hbc::CurlDownloadStrategy do
    let(:downloader) { Hbc::CurlDownloadStrategy.new(cask) }

    before do
      allow(downloader.temporary_path).to receive(:rename)
      allow(cask).to receive(:quarantine)
    end

    it "properly assigns a name and uri based on the Cask" do
      expect(downloader.name).to eq("some-cask")
      expect(downloader.url).to eq("http://example.com/cask.dmg")
      expect(downloader.version.to_s).to eq("1.2.3.4")
    end

    it "calls curl with default arguments for a simple Cask" do
      allow(downloader).to receive(:curl)

      downloader.fetch

      expect(downloader).to have_received(:curl).with(
        "--location",
        "--remote-time",
        "--continue-at", "-",
        "--output", kind_of(Pathname),
        cask.url.to_s,
        user_agent: :default
      )
    end

    context "with an explicit user agent" do
      let(:url_options) { { user_agent: "Mozilla/25.0.1" } }

      it "adds the appropriate curl args" do
        expect(downloader).to receive(:safe_system) { |*args|
          expect(args.each_cons(2)).to include(["--user-agent", "Mozilla/25.0.1"])
        }

        downloader.fetch
      end
    end

    context "with a generalized fake user agent" do
      alias_matcher :a_string_matching, :match

      let(:url_options) { { user_agent: :fake } }

      it "adds the appropriate curl args" do
        expect(downloader).to receive(:safe_system) { |*args|
          expect(args.each_cons(2).to_a).to include(["--user-agent", a_string_matching(/Mozilla.*Mac OS X 10.*AppleWebKit/)])
        }

        downloader.fetch
      end
    end

    context "with cookies set" do
      let(:url_options) {
        {
          cookies: {
            coo: "kie",
            mon: "ster",
          },
        }
      }

      it "adds curl args for cookies" do
        curl_args = []
        allow(downloader).to receive(:curl) { |*args| curl_args = args }

        downloader.fetch

        expect(curl_args.each_cons(2)).to include(["-b", "coo=kie;mon=ster"])
      end
    end

    context "with referer set" do
      let(:url_options) { { referer: "http://somehost/also" } }

      it "adds curl args for referer" do
        curl_args = []
        allow(downloader).to receive(:curl) { |*args| curl_args = args }

        downloader.fetch

        expect(curl_args.each_cons(2)).to include(["-e", "http://somehost/also"])
      end
    end
  end

  describe Hbc::CurlPostDownloadStrategy do
    let(:downloader) { Hbc::CurlPostDownloadStrategy.new(cask) }

    before do
      allow(downloader.temporary_path).to receive(:rename)
      allow(cask).to receive(:quarantine)
    end

    context "with :using and :data specified" do
      let(:url_options) {
        {
          using: :post,
          data:  {
            form: "data",
            is:   "good",
          },
        }
      }

      it "adds curl args for post arguments" do
        curl_args = []
        allow(downloader).to receive(:curl) { |*args| curl_args = args }

        downloader.fetch

        expect(curl_args.each_cons(2)).to include(["-d", "form=data"])
        expect(curl_args.each_cons(2)).to include(["-d", "is=good"])
      end
    end

    context "with :using but no :data" do
      let(:url_options) { { using: :post } }

      it "adds curl args for a POST request" do
        curl_args = []
        allow(downloader).to receive(:curl) { |*args| curl_args = args }

        downloader.fetch

        expect(curl_args.each_cons(2)).to include(["-X", "POST"])
      end
    end
  end

  describe Hbc::SubversionDownloadStrategy do
    let(:url_options) { { using: :svn } }
    let(:fake_system_command) { class_double(Hbc::SystemCommand) }
    let(:downloader) { Hbc::SubversionDownloadStrategy.new(cask, command: fake_system_command) }
    before do
      allow(fake_system_command).to receive(:run!)
    end

    it "returns a tarball path on fetch" do
      allow(downloader).to receive(:compress)
      allow(downloader).to receive(:fetch_repo)

      expect(downloader.fetch).to equal(downloader.cached_location)
    end

    it "calls fetch_repo with default arguments for a simple Cask" do
      allow(downloader).to receive(:compress)
      allow(downloader).to receive(:fetch_repo)

      downloader.fetch

      expect(downloader).to have_received(:fetch_repo).with(
        downloader.cached_location,
        cask.url.to_s,
      )
    end

    it "calls svn with default arguments for a simple Cask" do
      allow(downloader).to receive(:compress)

      downloader.fetch

      expect(fake_system_command).to have_received(:run!).with(
        "/usr/bin/svn",
        hash_including(args: [
                         "checkout",
                         "--force",
                         "--config-option",
                         "config:miscellany:use-commit-times=yes",
                         cask.url.to_s,
                         downloader.cached_location,
                       ]),
      )
    end

    context "with trust_cert set on the URL" do
      let(:url_options) {
        {
          using:      :svn,
          trust_cert: true,
        }
      }

      it "adds svn arguments for :trust_cert" do
        allow(downloader).to receive(:compress)

        downloader.fetch

        expect(fake_system_command).to have_received(:run!).with(
          "/usr/bin/svn",
          hash_including(args: [
                           "checkout",
                           "--force",
                           "--config-option",
                           "config:miscellany:use-commit-times=yes",
                           "--trust-server-cert",
                           "--non-interactive",
                           cask.url.to_s,
                           downloader.cached_location,
                         ]),
        )
      end
    end

    context "with :revision set on url" do
      let(:url_options) {
        {
          using:    :svn,
          revision: "10",
        }
      }

      it "adds svn arguments for :revision" do
        allow(downloader).to receive(:compress)

        downloader.fetch

        expect(fake_system_command).to have_received(:run!).with(
          "/usr/bin/svn",
          hash_including(args: [
                           "checkout",
                           "--force",
                           "--config-option",
                           "config:miscellany:use-commit-times=yes",
                           cask.url.to_s,
                           downloader.cached_location,
                           "-r",
                           "10",
                         ]),
        )
      end
    end
  end
end
