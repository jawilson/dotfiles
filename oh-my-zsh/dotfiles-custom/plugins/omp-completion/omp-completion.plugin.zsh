# COMPLETION FUNCTION
if (( ! $+commands[omp] )); then
  return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `omp`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_omp" ]]; then
  typeset -g -A _comps
  autoload -Uz _omp
  _comps[omp]=_omp
fi

omp completions zsh >| "$ZSH_CACHE_DIR/completions/_omp" &|
