# typed: true

module Cached
  requires_ancestor { Module }

  module Clear
    include Kernel
  end
end
