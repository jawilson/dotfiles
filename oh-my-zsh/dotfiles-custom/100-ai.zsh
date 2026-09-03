export OPENAI_API_KEY=$(get-cred-password "OpenAI API Key" 2> /dev/null)
export ANTHROPIC_API_KEY=$(get-cred-password "Anthropic API Key" 2> /dev/null)
export CURSOR_API_KEY=$(get-cred-password "Cursor API Key" 2> /dev/null)
export GEMINI_API_KEY=$(get-cred-password "Gemini API Key" 2> /dev/null)
export GITHUB_MCP_PERSONAL_ACCESS_TOKEN=$(get-cred-password "GitHub MCP PAT" 2> /dev/null)

# Antigravity
if ! command -v agy >/dev/null 2>&1; then
    if [ -n "$LOCALAPPDATA" ] && command -v cygpath >/dev/null 2>&1; then
        agy_bin=$(cygpath -u "$LOCALAPPDATA\\agy\\bin")
    else
        agy_bin="$HOME/.agy/bin"
    fi

    if [ -x "$agy_bin/agy" ]; then
        export PATH="$agy_bin:$PATH"
    fi
fi
