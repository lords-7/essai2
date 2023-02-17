#:  * `casks`
#:
#:  List all locally installable casks including short names.
#:

# HOMEBREW_LIBRARY is set in bin/brew
# shellcheck disable=SC2154
source "${HOMEBREW_LIBRARY}/Homebrew/items.sh"

homebrew-casks() {
  local casks
  casks="$(homebrew-items '*/Casks/*\.rb' '' 's|/Casks/|/|' '^homebrew/cask')"

  # HOMEBREW_CACHE is set by brew.sh
  # shellcheck disable=SC2154
  if [[ -z "${HOMEBREW_NO_INSTALL_FROM_API}" &&
        -f "${HOMEBREW_CACHE}/api/cask.json" ]]
  then
    local api_casks
    api_casks="$(ruby -e "require 'json'; JSON.parse(File.read('${HOMEBREW_CACHE}/api/cask.json')).each { |f| puts f['token'] }" 2>/dev/null)"
    casks="$(echo -e "${casks}\n${api_casks}" | sort -uf | grep .)"
  fi

  echo "${casks}"
}
