#:  * `shellenv`
#:
#:  Print export statements. When run in a shell, this installation of Homebrew will be added to your `PATH`, `MANPATH`, and `INFOPATH`.
#:
#:  The variables `HOMEBREW_PREFIX`, `HOMEBREW_CELLAR`, `HOMEBREW_REPOSITORY`, and `HOMEBREW_CACHE`  are also exported to avoid querying them multiple times.
#:  To help guarantee idempotence, this command produces no output when Homebrew's `bin` and `sbin` directories are first and second
#:  respectively in your `PATH`. Consider adding evaluation of this command's output to your dotfiles (e.g. `~/.profile`,
#:  `~/.bash_profile`, or `~/.zprofile`) with: `eval "$(brew shellenv)"`

# HOMEBREW_CELLAR and HOMEBREW_PREFIX are set by extend/ENV/super.rb
# HOMEBREW_REPOSITORY is set by bin/brew
# HOMEBREW_DEFAULT_CACHE is set by Library/Homebrew/brew.sh
# Trailing colon in MANPATH adds default man dirs to search path in Linux, does no harm in macOS.
# Please do not submit PRs to remove it!
# shellcheck disable=SC2154
homebrew-shellenv() {
  if [[ "${HOMEBREW_PATH%%:"${HOMEBREW_PREFIX}"/sbin*}" == "${HOMEBREW_PREFIX}/bin" ]]
  then
    return
  fi

  case "$(/bin/ps -p "${PPID}" -c -o comm=)" in
    fish | -fish)
      echo "set -gx HOMEBREW_PREFIX \"${HOMEBREW_PREFIX}\";"
      echo "set -gx HOMEBREW_CELLAR \"${HOMEBREW_CELLAR}\";"
      echo "set -gx HOMEBREW_REPOSITORY \"${HOMEBREW_REPOSITORY}\";"
      echo "set -q HOMEBREW_CACHE; or set HOMEBREW_CACHE ''; set -gx HOMEBREW_CACHE \"${HOMEBREW_DEFAULT_CACHE}\""
      echo "set -q PATH; or set PATH ''; set -gx PATH \"${HOMEBREW_PREFIX}/bin\" \"${HOMEBREW_PREFIX}/sbin\" \$PATH;"
      echo "set -q MANPATH; or set MANPATH ''; set -gx MANPATH \"${HOMEBREW_PREFIX}/share/man\" \$MANPATH;"
      echo "set -q INFOPATH; or set INFOPATH ''; set -gx INFOPATH \"${HOMEBREW_PREFIX}/share/info\" \$INFOPATH;"
      ;;
    csh | -csh | tcsh | -tcsh)
      echo "setenv HOMEBREW_PREFIX ${HOMEBREW_PREFIX};"
      echo "setenv HOMEBREW_CELLAR ${HOMEBREW_CELLAR};"
      echo "setenv HOMEBREW_REPOSITORY ${HOMEBREW_REPOSITORY};"
      echo "if ( ! \$?HOMEBREW_CACHE ) setenv HOMEBREW_CACHE ${HOMEBREW_DEFAULT_CACHE};"
      echo "setenv PATH ${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:\$PATH;"
      echo "setenv MANPATH ${HOMEBREW_PREFIX}/share/man\`[ \${?MANPATH} == 1 ] && echo \":\${MANPATH}\"\`:;"
      echo "setenv INFOPATH ${HOMEBREW_PREFIX}/share/info\`[ \${?INFOPATH} == 1 ] && echo \":\${INFOPATH}\"\`;"
      ;;
    pwsh | -pwsh | pwsh-preview | -pwsh-preview)
      setvar="[System.Environment]::SetEnvironmentVariable"
      pwshusr="[System.EnvironmentVariableTarget]::Process"
      echo "${setvar}('HOMEBREW_PREFIX','${HOMEBREW_PREFIX}',${pwshusr})"
      echo "${setvar}('HOMEBREW_CELLAR','${HOMEBREW_CELLAR}',${pwshusr})"
      echo "${setvar}('HOMEBREW_REPOSITORY','${HOMEBREW_REPOSITORY}',${pwshusr})"
      echo "if (![System.Environment]::GetEnvironmentVariable('HOMEBREW_CACHE',${pwshusr})) { ${setvar}('HOMEBREW_CACHE','${HOMEBREW_DEFAULT_CACHE}',${pwshusr}) }"
      echo "${setvar}('PATH',\$('${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:'+\$ENV:PATH),${pwshusr})"
      echo "${setvar}('MANPATH',\$('${HOMEBREW_PREFIX}/share/man'+\$(if(\${ENV:MANPATH}){':'+\${ENV:MANPATH}})+':'),${pwshusr})"
      echo "${setvar}('INFOPATH',\$('${HOMEBREW_PREFIX}/share/info'+\$(if(\${ENV:INFOPATH}){':'+\${ENV:INFOPATH}})),${pwshusr})"
      ;;
    *)
      echo "export HOMEBREW_PREFIX=\"${HOMEBREW_PREFIX}\";"
      echo "export HOMEBREW_CELLAR=\"${HOMEBREW_CELLAR}\";"
      echo "export HOMEBREW_REPOSITORY=\"${HOMEBREW_REPOSITORY}\";"
      echo "export HOMEBREW_CACHE=\"\${HOMEBREW_CACHE:-${HOMEBREW_DEFAULT_CACHE}}\";"
      echo "export PATH=\"${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin\${PATH+:\$PATH}\";"
      echo "export MANPATH=\"${HOMEBREW_PREFIX}/share/man\${MANPATH+:\$MANPATH}:\";"
      echo "export INFOPATH=\"${HOMEBREW_PREFIX}/share/info:\${INFOPATH:-}\";"
      ;;
  esac
}
