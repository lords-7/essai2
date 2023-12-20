# typed: true
# frozen_string_literal: true

# Used to track formulae that cannot be installed at the same time.
FormulaConflict = Struct.new(:name, :reason) do
  def conflict_message
    message = []
    message << "  #{name}"
    message << ": because #{reason}" if reason
    message.join
  end

  def conflicts?(formula_or_cask)
    f = Formulary.factory(name)
  rescue TapFormulaUnavailableError
    # If the formula name is a fully-qualified name let's silently
    # ignore it as we don't care about things used in taps that aren't
    # currently tapped.
    false
  rescue FormulaUnavailableError => e
    # If the formula name doesn't exist any more then complain but don't
    # stop installation from continuing.
    official_tap, filename = if formula_or_cask.is_a?(Formula)
      ["homebrew-core", formula_or_cask.path.basename]
    else
      ["homebrew-cask", formula_or_cask.sourcefile_path.basename]
    end
    opoo <<~EOS
      #{formula_or_cask}: #{e.message}
      'conflicts_with "#{name}"' should be removed from #{filename}.
    EOS

    raise if Homebrew::EnvConfig.developer?

    $stderr.puts "Please report this issue to the #{formula_or_cask.tap} tap " \
                 "(not Homebrew/brew or Homebrew/#{official_tap})!"
    false
  else
    f.linked_keg.exist? && f.opt_prefix.exist?
  end
end
