module OS
  def self.mac?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]

    RbConfig::CONFIG["host_os"].include? "darwin"
  end

  def self.linux?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]

    host_os = RbConfig::CONFIG["host_os"]
    host_os.include?("linux") || host_os == "cygwin"
  end

  def self.cygwin?
    return false if ENV["HOMEBREW_TEST_GENERIC_OS"]

    RbConfig::CONFIG["host_os"] == "cygwin"
  end

  ::OS_VERSION = ENV["HOMEBREW_OS_VERSION"]

  if OS.mac?
    require "os/mac"
    # Don't tell people to report issues on unsupported configurations.
    if !OS::Mac.prerelease? &&
       !OS::Mac.outdated_release? &&
       ARGV.none? { |v| v.start_with?("--cc=") } &&
       ENV["HOMEBREW_PREFIX"] == "/usr/local"
      ISSUES_URL = "https://docs.brew.sh/Troubleshooting".freeze
    end
    PATH_OPEN = "/usr/bin/open".freeze
  elsif OS.linux?
    require "os/linux"
    ISSUES_URL = "https://docs.brew.sh/Troubleshooting".freeze
    PATH_OPEN = "xdg-open".freeze
  end
end
