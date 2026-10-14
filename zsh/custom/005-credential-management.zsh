# Credentials come from fnox. fnox.toml in this repository maps each variable to an item in
# the profile's vault (1Password for work, Vaultwarden for personal). `mise run
# credentials:sync` caches the values in fnox.local.toml, age-encrypted with this machine's
# key, so reading them is local and shell startup never runs `op` or `bw`.

# The profile install.sh recorded in .miserc.local.toml (env = ["work"]); fnox.toml uses the
# same profile names.
typeset -g _DOTFILES_PROFILE=
if [[ -r $DOTFILES_DIR/.miserc.local.toml ]]; then
  () {
    local line
    while IFS= read -r line; do
      if [[ $line == 'env = ["'*'"]' ]]; then
        _DOTFILES_PROFILE=${${line#'env = ["'}%'"]'}
        return
      fi
    done < $DOTFILES_DIR/.miserc.local.toml
  }
fi

# Runs fnox on this repository's fnox.toml with this machine's profile.
_dotfiles_fnox() {
  if [[ -z $_DOTFILES_PROFILE ]]; then
    echo "No profile in $DOTFILES_DIR/.miserc.local.toml; run install.sh --profile work|personal." >&2
    return 1
  fi
  local fnox_bin=${commands[fnox]}
  # Agent terminals skip mise activation, so fnox may not be on PATH.
  if [[ -z $fnox_bin ]] && (( $+commands[mise] )); then
    fnox_bin=$(mise which fnox 2>/dev/null)
  fi
  if [[ -z $fnox_bin ]]; then
    echo "fnox is not installed; run 'mise bootstrap' in $DOTFILES_DIR." >&2
    return 1
  fi
  # cd -q skips chpwd hooks (mise) in the subshell.
  ( builtin cd -q -- "$DOTFILES_DIR" && "$fnox_bin" --non-interactive -P "$_DOTFILES_PROFILE" "$@" )
}

# Prints one credential by its fnox.toml name, including ones that are not exported
# (env = false), such as GHCR_TOKEN.
get-cred-password() {
  if [[ -z $1 ]]; then
    echo "Usage: get-cred-password <name in fnox.toml>" >&2
    return 1
  fi
  _dotfiles_fnox get "$1"
}

# Export the credentials once per shell. Waiting for credentials:sync to create the cache
# means a machine without it never contacts a vault at startup.
if [[ -r $DOTFILES_DIR/fnox.local.toml ]]; then
  eval "$(_dotfiles_fnox export --format shell 2>/dev/null)"
fi
