#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_CACHE_HOME="$tmp/cache"
mkdir -p "$HOME" "$tmp/bin" "$tmp/remote"
git -C "$tmp/remote" init -q
git -C "$tmp/remote" config user.email test@example.com
git -C "$tmp/remote" config user.name Test
echo initial > "$tmp/remote/fnox.toml"
git -C "$tmp/remote" add fnox.toml
git -C "$tmp/remote" commit -qm initial
git clone -q "$tmp/remote" "$tmp/local"
echo changed > "$tmp/remote/fnox.toml"
git -C "$tmp/remote" commit -qam changed
output=$(DOTFILES_DIR="$tmp/local" zsh "$repo/tools/dotfiles-update.zsh" --no-dot-apply --no-bootstrap </dev/null)
[[ "$output" == *"Credential configuration changed; run 'mise run credentials:sync'"* ]]
echo unrelated > "$tmp/remote/other"
git -C "$tmp/remote" add other
git -C "$tmp/remote" commit -qm unrelated
output=$(DOTFILES_DIR="$tmp/local" zsh "$repo/tools/dotfiles-update.zsh" --no-dot-apply --no-bootstrap </dev/null)
[[ "$output" != *"Credential configuration changed"* ]]
cat > "$tmp/bin/mise" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/mise-calls"
EOF
chmod +x "$tmp/bin/mise"
export PATH="$tmp/bin:$PATH" DOTFILES_DIR="$tmp/local"
echo again > "$tmp/remote/fnox.toml"
git -C "$tmp/remote" commit -qam again
printf 'y\n' | script -q -c "zsh '$repo/tools/dotfiles-update.zsh' --no-dot-apply --no-bootstrap" /dev/null >/dev/null
grep -qx 'run credentials:sync' "$HOME/mise-calls"
rm "$HOME/mise-calls"
echo more > "$tmp/remote/fnox.toml"
git -C "$tmp/remote" commit -qam more
printf 'n\n' | script -q -c "zsh '$repo/tools/dotfiles-update.zsh' --no-dot-apply --no-bootstrap" /dev/null >/dev/null
[[ ! -e "$HOME/mise-calls" ]]
mkdir -p "$tmp/installer/tools"
cp "$repo/install.sh" "$tmp/installer/install.sh"
cp "$repo/tools/common.sh" "$tmp/installer/tools/common.sh"
rm -f "$HOME/mise-calls"
printf 'y\n' | script -q -c "bash '$tmp/installer/install.sh' --profile personal --no-run-zsh" /dev/null >/dev/null
grep -qx -- '-E personal run credentials:sync' "$HOME/mise-calls"
rm "$HOME/mise-calls"
printf 'n\n' | script -q -c "bash '$tmp/installer/install.sh' --profile personal --no-run-zsh" /dev/null >/dev/null
! grep -q 'credentials:sync' "$HOME/mise-calls"
echo 'Credential update regression passed.'