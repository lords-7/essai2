if OS.mac?
  require "extend/os/mac/formula_cellar_checks"
elsif OS.linux?
  require "extend/os/linux/formula_cellar_checks"
elsif OS.cygwin?
  require "extend/os/cygwin/formula_cellar_checks"
end
