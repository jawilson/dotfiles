# COMPLETION FUNCTION
if (( ! $+commands[dvm] )); then
  return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `dvm`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_dvm" ]]; then
  typeset -g -A _comps
  autoload -Uz _dvm
  _comps[dvm]=_dvm
fi

dvm completions zsh >| "$ZSH_CACHE_DIR/completions/_dvm" &|
