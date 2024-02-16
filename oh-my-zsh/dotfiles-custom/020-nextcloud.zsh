if ! command -v curl &> /dev/null || [ -z "$BW_SESSION" ]; then
    return 0
fi

_get_

nxtup() {
    if [ -z "$1" ]; then
        echo "Usage: nxtup <local_file> [remote_file]"
        return 1
    fi

    local bw_item=$(bw list items | jq -r '.[] | select(.name == "Nextcloud" and (.fields[] | select(.name == "CLI App Password")))')
    if [ -z "$bw_item" ]; then
        echo "Nextcloud item not found in Bitwarden"
        return 1
    fi

    local bw_username=$(echo $bw_item | jq -r '.login.username')
    local bw_app_password=$(echo $bw_item | jq -r '.fields[] | select(.name == "CLI App Password") | .value')
    local bw_vault_uri=$(echo $bw_item | jq -r '[.login.uris[] | select(.uri | startswith("https://"))][0] | .uri')

    local upload_url="$bw_vault_uri/remote.php/dav/files/$(omz_urlencode $bw_username)/$(omz_urlencode ${2:-$1})"
    curl -u "$bw_username:$bw_app_password" -T "$1" "$upload_url"
}
