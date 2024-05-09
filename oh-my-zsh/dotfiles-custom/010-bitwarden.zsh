if [ "$BITWARDEN_DISABLE_SETUP" = "true" ]; then
    return 0
fi

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

local has_jq=$(command -v jq &>/dev/null && echo true || echo false)
local BW_SERVER_URL="https://vault.jeffalwilson.com"

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


local has_data_file=false
if [ -f "$BW_DATA_FILE" ]; then
    has_data_file=true
fi

if $has_data_file && $has_jq && jq -e 'has(.activeUserId) and .[.activeUserId].profile.userId == .activeUserId' $BW_DATA_FILE &>/dev/null; then
    # Just need to unlock the session
    bwul
    return 0
fi

# Ensure server is correctly set
if ! $has_data_file || ($has_jq && [ "$(jq -r '.global_environment_environment.urls.base' $BW_DATA_FILE)" != "${BW_SERVER_URL}" ]); then
    bw config server ${BW_SERVER_URL}
fi

if [ -f "$HOME/.bitwarden/credentials" ]; then
    (
        export $(grep -v '^#' ~/.bitwarden/credentials | xargs)
        bw login --apikey
    )
    bwul
    return 0
fi

local bw_server_host=$(basename $BW_SERVER_URL)
case "$OSTYPE" in
    darwin*)
      BW_CLIENTID=$(security find-internet-password -s $bw_server_host -g 2>/dev/null | grep -E "acct" |  rev  | cut -d'"' -f2 |  rev)
      BW_CLIENTSECRET=$(security find-internet-password -w -s $bw_server_host 2>/dev/null)
      if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
        (
            export BW_CLIENTID
            export BW_CLIENTSECRET
            bw login --apikey
        )
        bwul
        return 0
      fi
      ;;
esac

if ! $has_data_file; then
    echo "Bitwarden CLI data file not found, use 'bw login' to login"
elif ! $has_jq || ! jq -e 'has(.activeUserId) and .[.activeUserId].profile.userId == .activeUserId' $BW_DATA_FILE &>/dev/null; then
    echo "Bitwarden CLI data file is not logged in and no API key found, use 'bw login' to login"
fi












if ! $has_data_file || ! $has_jq || ! jq -e 'has(.activeUserId) and .[.activeUserId].profile.userId == .activeUserId' $BW_DATA_FILE &>/dev/null; then


    if $has_data_file && ! $has_jq; then
        echo "jq is required to parse Bitwarden CLI data file, will attempt to login, but this may fail"
    fi

    # Ensure server is correctly set
    if ! $has_data_file || ! $has_jq || [ "$(jq -r '.global_environment_environment.urls.base' $BW_DATA_FILE)" != "${BW_SERVER_URL}" ]; then
        bw config server ${BW_SERVER_URL}
    fi


    if has_data_file && has_jq; then
        # Needs to be logged in

        local api_key=$(get-cred-password $BW_SERVER_URL)



    if [ ! -f "$BW_DATA_FILE" ] || ! $has_jq || [ "$(jq -r '.global_environment_environment.urls.base' $BW_DATA_FILE)" != "${BW_SERVER_URL}" ]; then
        bw config server ${BW_SERVER_URL}
    fi

    if [ -f "$HOME/.bitwarden/credentials" ]; then
        # Login with API key
        (
            export $(grep -v '^#' ~/.bitwarden/credentials | xargs)
            bw login --apikey
        )
    elif [ ! -f "$BW_DATA_FILE" ]; then
        echo "Bitwarden CLI data file not found, use 'bw login' to login"
    elif ! jq -e 'has(.activeUserId) and .[.activeUserId].profile.userId == .activeUserId' $BW_DATA_FILE &>/dev/null; then
        echo "Bitwarden CLI data file is invalid, use 'bw login' to login"
    fi
fi
