#!/usr/bin/env bash
# Caches this profile's credentials from 1Password (work) or Vaultwarden (personal) in
# fnox.local.toml, age-encrypted with this machine's key. zsh reads only that cache.
# Run through `mise run credentials:sync`, which sets FNOX_PROFILE and the tool PATH.
# No `-u`: common.sh reads $MSYSTEM unguarded.
set -eo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${script_dir}/common.sh"
# --local-file needs the repository as the working directory.
cd "${script_dir}/.."

if [ "$FNOX_PROFILE" != work ] && [ "$FNOX_PROFILE" != personal ]; then
  echo "credentials:sync: FNOX_PROFILE is not work or personal; run 'mise run credentials:sync' in the repository." >&2
  exit 1
fi

# fnox's global config directory, resolved the way fnox does.
if [ -n "$FNOX_CONFIG_DIR" ]; then
  fnox_dir=$FNOX_CONFIG_DIR
elif [ -n "$XDG_CONFIG_HOME" ]; then
  fnox_dir=$XDG_CONFIG_HOME/fnox
elif is_windows_native; then
  fnox_dir="$(cygpath -u "$USERPROFILE")/AppData/Local/fnox"
else
  fnox_dir=$HOME/.config/fnox
fi

if [ ! -f "$fnox_dir/age.txt" ]; then
  mkdir -p "$fnox_dir"
  (umask 077 && age-keygen -o "$fnox_dir/age.txt")
fi

if ! grep -q '^\[providers\.sync-age\]' "$fnox_dir/config.toml" 2> /dev/null; then
  recipient=$(age-keygen -y "$fnox_dir/age.txt")
  cat >> "$fnox_dir/config.toml" << EOF

[providers.sync-age]
type = "age"
recipients = ["$recipient"]
key_file = "age.txt"
EOF
fi

if [ "$(fnox sync --provider sync-age --local-file --dry-run)" = "No secrets to sync" ]; then
  echo "credentials:sync: fnox.toml maps no credentials for the $FNOX_PROFILE profile."
  exit 0
fi

sync_log=$(mktemp)
lock_bitwarden=no
cleanup() {
  rm -f "$sync_log"
  if [ "$lock_bitwarden" = yes ]; then
    bw lock > /dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ "$FNOX_PROFILE" = personal ]; then
  bw_status=$(bw status)
  if [[ $bw_status == *'"serverUrl":null'* ]]; then
    read -r -p "Vaultwarden URL: " server_url
    bw config server "$server_url"
  fi
  if [[ $bw_status == *'"status":"unauthenticated"'* ]]; then
    BW_SESSION=$(bw login --raw)
    lock_bitwarden=yes
  elif [[ $bw_status != *'"status":"unlocked"'* ]]; then
    BW_SESSION=$(bw unlock --raw)
    lock_bitwarden=yes
  fi
  export BW_SESSION
  bw sync > /dev/null
else
  op whoami > /dev/null 2>&1 || eval "$(op signin)"
fi

fnox sync --provider sync-age --local-file --force 2>&1 | tee "$sync_log"

if grep -Eq '^Skipped [0-9]+ secrets' "$sync_log"; then
  echo "credentials:sync: fix the references of the skipped entries in fnox.toml ([profiles.$FNOX_PROFILE.secrets]) or comment them out, then run it again. Until then every new shell asks the vault for them." >&2
  exit 1
fi

echo "credentials:sync: open a new shell to load the credentials."
