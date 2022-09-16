# typed: strict
# frozen_string_literal: true

if OS.mac?
  require "extend/os/mac/utils/bottles"
elsif OS.linux?
  require "extend/os/linux/utils/bottles"
end
