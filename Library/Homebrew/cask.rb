# typed: strict
# frozen_string_literal: true

require "cask/macos"
require "cask/exceptions"

module Cask
  autoload :Artifact, "cask/artifact"
  autoload :ArtifactSet, "cask/artifact_set"
  autoload :Audit, "cask/audit"
  autoload :Auditor, "cask/auditor"
  autoload :Cache, "cask/cache"
  autoload :CaskLoader, "cask/cask_loader"
  autoload :Cask, "cask/cask"
  autoload :Caskroom, "cask/caskroom"
  autoload :Cmd, "cask/cmd"
  autoload :Config, "cask/config"
  autoload :Denylist, "cask/denylist"
  autoload :Download, "cask/download"
  autoload :DSL, "cask/dsl"
  autoload :Info, "cask/info"
  autoload :Installer, "cask/installer"
  autoload :List, "cask/list"
  autoload :Metadata, "cask/metadata"
  autoload :Pkg, "cask/pkg"
  autoload :Quarantine, "cask/quarantine"
  autoload :Staged, "cask/staged"
  autoload :Uninstall, "cask/uninstall"
  autoload :Upgrade, "cask/upgrade"
  autoload :Utils, "cask/utils"
end
