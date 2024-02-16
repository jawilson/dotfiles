
if [ ! -f "$(which bw)" ]; then
    return 0
fi

case "$OSTYPE" in
    linux*)
      BW_DATA_FILE="$HOME/.config/Bitwarden/data.json"
      BW_SESSION_FILE="$XDG_RUNTIME_DIR/bw-cli-session"
      ;;
    darwin*)
      BW_DATA_FILE="$HOME/Library/Application Support/Bitwarden CLI/data.json"
      BW_SESSION_FILE="$HOME/Library/Caches/Bitwarden CLI/bw-cli-session"
      ;;
    *)
      return 0
esac

bwul() {
    echo "Unlocking Bitwarden CLI..."
    BW_SESSION=$(bw unlock --raw)
    if [ $? -ne 0 ] || [ -z "$BW_SESSION" ]; then
        echo "\nFailed to unlock Bitwarden CLI, use 'bwul' to try again"
        return 0
    fi
    install -d -m 700 "$(dirname "$BW_SESSION_FILE")"
    echo $BW_SESSION > "$BW_SESSION_FILE"
    chmod 600 "$BW_SESSION_FILE"
    export BW_SESSION
}

if [ -f "$BW_SESSION_FILE" ]; then
    export BW_SESSION=$(cat $BW_SESSION_FILE)
    return 0
fi

if [ ! -f "$BW_DATA_FILE" ] || ! command -v jq &>/dev/null || ! jq -e 'has(.activeUserId) and .[.activeUserId].profile.userId == .activeUserId' $BW_DATA_FILE &>/dev/null; then
    if [ -f "$HOME/.bitwarden/credentials" ]; then
        # Login with API key
        (
            export $(grep -v '^#' ~/.bitwarden/credentials | xargs)
            bw login --apikey
        )
    else
        # Login with email/password
        echo "Logging into Bitwarden CLI"
        bw login
    fi
fi

bwul
