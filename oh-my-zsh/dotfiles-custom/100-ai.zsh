export OPENAI_API_KEY=$(get-cred-password "OpenAI API Key" 2> /dev/null)
export ANTHROPIC_API_KEY=$(get-cred-password "Anthropic API Key" 2> /dev/null)
export CURSOR_API_KEY=$(get-cred-password "Cursor API Key" 2> /dev/null)
export GITHUB_MCP_PERSONAL_ACCESS_TOKEN=$(get-cred-password "GitHub MCP PAT" 2> /dev/null)
