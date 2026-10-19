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

# VS Code and Google Chrome from the vendors' apt repositories. Skipped on WSL and in
# Codespaces, where the Windows or host copies are used (a Linux `code` would shadow the
# Windows one that VS Code Remote relies on).
if [ ! -e /proc/sys/fs/binfmt_misc/WSLInterop ] && [ -z "${CODESPACES:-}" ]; then
    gui_pkgs=()
    if ! deb_installed code; then
        as_root install -d -m 0755 /etc/apt/keyrings
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | as_root tee /etc/apt/keyrings/microsoft.asc > /dev/null
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.asc] https://packages.microsoft.com/repos/code stable main" |
            as_root tee /etc/apt/sources.list.d/vscode.list > /dev/null
        # Stop the package from adding a second copy of this repository (apt rejects conflicting Signed-By values).
        echo "code code/add-microsoft-repo boolean false" | as_root debconf-set-selections
        gui_pkgs+=(code)
    fi
    arch=$(dpkg --print-architecture)
    if [ "$arch" != amd64 ]; then
        echo "bootstrap: skipped Google Chrome: Google publishes no Linux build for $arch" >&2
    elif ! deb_installed google-chrome-stable; then
        as_root install -d -m 0755 /etc/apt/keyrings
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | as_root tee /etc/apt/keyrings/google-chrome.asc > /dev/null
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.asc] https://dl.google.com/linux/chrome/deb/ stable main" |
            as_root tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
        gui_pkgs+=(google-chrome-stable)
    fi
    if [ "${#gui_pkgs[@]}" -gt 0 ]; then
        as_root apt-get update -q
        as_root env DEBIAN_FRONTEND=noninteractive apt-get install -qy "${gui_pkgs[@]}"
    fi
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
