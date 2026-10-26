#!/usr/bin/env bash
# Imperative Linux setup, run as the `bootstrap` task from mise.linux.toml.
# Every step checks first, so `mise bootstrap` can run it again.
set -euo pipefail

as_root() {
    if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# dpkg -s also succeeds for removed-but-configured or half-installed packages.
deb_installed() {
    [ "$(dpkg-query -W -f='${Status}' "$1" 2> /dev/null)" = "install ok installed" ]
}

# uv and oh-my-pi: no apt packages; both install into ~/.local/bin, which zshrc puts on PATH.
if [ ! -x "$HOME/.local/bin/uv" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi
if [ ! -x "$HOME/.local/bin/omp" ]; then
    curl -fsSL https://omp.sh/install | sh -s -- --binary
fi

# eza: in Debian 13+ and Ubuntu 24.04+, but not Debian 12 or older Ubuntu. Where the distro has
# no package, use the eza project's apt repository.
if ! deb_installed eza; then
    if ! apt-cache show eza > /dev/null 2>&1; then
        as_root install -d -m 0755 /etc/apt/keyrings
        curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | as_root tee /etc/apt/keyrings/gierens.asc > /dev/null
        echo "deb [signed-by=/etc/apt/keyrings/gierens.asc] https://deb.gierens.de stable main" |
            as_root tee /etc/apt/sources.list.d/gierens.list > /dev/null
        as_root apt-get update -q
    fi
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -qy eza
fi

# WSL: npiperelay lets zshrc reach the Windows ssh-agent through socat.
if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] && [ -z "${NPIPERELAY:-}" ]; then
    userprofile=$(wslpath "$(cmd.exe /c "echo %USERPROFILE%" 2> /dev/null | tr -d '\r')")
    mkdir -p "$userprofile/bin"
    curl -fsSL https://github.com/jstarks/npiperelay/releases/latest/download/npiperelay_windows_amd64.zip -o /tmp/npiperelay.zip
    unzip -o /tmp/npiperelay.zip npiperelay.exe -d "$userprofile/bin"
    chmod +x "$userprofile/bin/npiperelay.exe"
    rm -f /tmp/npiperelay.zip
    cmd.exe /c "setx NPIPERELAY %USERPROFILE%\\bin\\npiperelay.exe"
    win_wslenv=$(cmd.exe /c "echo %WSLENV%" 2> /dev/null | tr -d '\r')
    if [[ "$win_wslenv" != *NPIPERELAY/p* ]]; then
        cmd.exe /c "setx WSLENV \"${win_wslenv:+${win_wslenv}:}NPIPERELAY/p\""
    fi
fi

# Codespaces: GitHub Packages npm auth.
if [ -n "${CODESPACES:-}" ] && [ -n "${GH_PACKAGE_REGISTRY_TOKEN:-}" ] &&
    ! grep -F '//npm.pkg.github.com/:_authToken=' "$HOME/.npmrc" > /dev/null 2>&1; then
    echo "//npm.pkg.github.com/:_authToken=$GH_PACKAGE_REGISTRY_TOKEN" >> "$HOME/.npmrc"
fi
