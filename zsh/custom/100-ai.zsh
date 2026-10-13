export OPENAI_API_KEY=$(get-cred-password "OpenAI API Key" 2> /dev/null)
export ANTHROPIC_API_KEY=$(get-cred-password "Anthropic API Key" 2> /dev/null)
export CURSOR_API_KEY=$(get-cred-password "Cursor API Key" 2> /dev/null)
export GITHUB_MCP_PERSONAL_ACCESS_TOKEN=$(get-cred-password "GitHub MCP PAT" 2> /dev/null)

if (( $+commands[omp] )); then
  _omp_prompt() {
    local extra_system_prompt=$1
    local -a system_prompt=(
      'This is a non-interactive command-line invocation (`omp -p`). The caller cannot answer follow-up questions. Complete the requested task autonomously; state any unavoidable blocker in the final response.'
    )
    shift
    [[ -n $extra_system_prompt ]] && system_prompt+=("$extra_system_prompt")

    omp -p \
      --model "openai/gpt-5.6-luna" \
      --no-skills \
      --no-session \
      --append-system-prompt "${(F)system_prompt}" \
      "$@"
  }

  _ompx() {
    _omp_prompt \
      'Execute the request; do not only explain how to do it.' \
      "$@"
  }

  ompp() {
    _omp_prompt '' \
      --thinking off \
      --no-tools \
      "$*"
  }
  omppt() {
    _omp_prompt '' \
      --thinking minimal \
      "$*"
  }

  ompx() {
    _ompx \
      --thinking off \
      "$*"
  }

  ompxt() {
    _ompx \
      --thinking minimal \
      "$*"
  }

  ompxa() {
    _ompx \
      --thinking off \
      --auto-approve \
      "$*"
  }

  ompxta() {
    _ompx \
      --thinking minimal \
      --auto-approve \
      "$*"
  }
fi
