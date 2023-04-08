# typed: strict
# frozen_string_literal: true

module Cask
  # Module containing all cask artifact classes.
  #
  # @api private
  module Artifact
    autoload :AbstractArtifact, "cask/artifact/abstract_artifact"
    autoload :AbstractFlightBlock, "cask/artifact/abstract_flight_block"
    autoload :AbstractUninstall, "cask/artifact/abstract_uninstall"
    autoload :App, "cask/artifact/app"
    autoload :Artifact, "cask/artifact/artifact" # generic 'artifact' stanza
    autoload :AudioUnitPlugin, "cask/artifact/audio_unit_plugin"
    autoload :Binary, "cask/artifact/binary"
    autoload :Colorpicker, "cask/artifact/colorpicker"
    autoload :Dictionary, "cask/artifact/dictionary"
    autoload :Font, "cask/artifact/font"
    autoload :InputMethod, "cask/artifact/input_method"
    autoload :Installer, "cask/artifact/installer"
    autoload :InternetPlugin, "cask/artifact/internet_plugin"
    autoload :KeyboardLayout, "cask/artifact/keyboard_layout"
    autoload :Manpage, "cask/artifact/manpage"
    autoload :Mdimporter, "cask/artifact/mdimporter"
    autoload :Moved, "cask/artifact/moved"
    autoload :Pkg, "cask/artifact/pkg"
    autoload :PostflightBlock, "cask/artifact/postflight_block"
    autoload :PreflightBlock, "cask/artifact/preflight_block"
    autoload :Prefpane, "cask/artifact/prefpane"
    autoload :Qlplugin, "cask/artifact/qlplugin"
    autoload :Relocated, "cask/artifact/relocated"
    autoload :ScreenSaver, "cask/artifact/screen_saver"
    autoload :Service, "cask/artifact/service"
    autoload :StageOnly, "cask/artifact/stage_only"
    autoload :Suite, "cask/artifact/suite"
    autoload :Symlinked, "cask/artifact/symlinked"
    autoload :Uninstall, "cask/artifact/uninstall"
    autoload :VstPlugin, "cask/artifact/vst_plugin"
    autoload :Vst3Plugin, "cask/artifact/vst3_plugin"
    autoload :Zap, "cask/artifact/zap"
  end
end
