#!/usr/bin/env bash
# Imperative macOS setup, run as the `bootstrap` task from mise.macos.toml.
# Every step checks first, so `mise bootstrap` can run it again. Login items are
# LaunchAgents in mise.macos.toml, not steps here.
set -euo pipefail

# mise cannot install these. It source-builds omp's formula (no bottle) and its shim lacks
# `with_env`; it cannot uninstall the Packages cask's pkg without pkgutil ids; and the
# Docker Desktop cask links into root-owned /usr/local/bin, which mise fails to fingerprint.
# --adopt keeps a Docker.app that is already installed.
if ! brew list --formula omp > /dev/null 2>&1; then
    brew install can1357/tap/omp
fi
if ! brew list --cask packages > /dev/null 2>&1; then
    brew install --cask packages
fi
if ! brew list --cask docker-desktop > /dev/null 2>&1; then
    brew install --cask --adopt docker-desktop
fi

# Finder sidebar favorites: the home directory at the top and ~/src (created by
# [bootstrap.directories] in mise.toml) at the bottom. Compiled into a temporary
# directory, since `swift` crashes interpreting the file.
favorites_dir=$(mktemp -d)
trap 'rm -rf "$favorites_dir"' EXIT
swiftc -suppress-warnings -o "$favorites_dir/finder-favorites" "$(dirname "${BASH_SOURCE[0]}")/finder-favorites.swift"
"$favorites_dir/finder-favorites" --first "$HOME" --last "$HOME/src"

# Chrome as the default browser. macOS shows a confirmation dialog the first time; click "Use Chrome".
if [ -d "/Applications/Google Chrome.app" ] && ! defaults export com.apple.LaunchServices/com.apple.launchservices.secure - |
    plutil -convert json -o - - |
    jq -e '.LSHandlers[] | select(.LSHandlerURLScheme == "https" and .LSHandlerRoleAll == "com.google.chrome")' > /dev/null; then
    defaultbrowser chrome
fi

# 1Password as an AutoFill provider (System Settings > General > AutoFill & Passwords). The work
# profile gets 1Password from MDM, so the extension may not exist yet; run `mise bootstrap` again then.
if [ -d /Applications/1Password.app ]; then
    pluginkit -e use -i com.1password.1password.autofill-extension
else
    echo "bootstrap: 1Password is not installed; run 'mise bootstrap' again to enable its AutoFill extension" >&2
fi

# Rust toolchain. zshrc and ~/.zshenv source ~/.cargo/env; --no-modify-path stops
# rustup from appending to ~/.bashrc, which is a link into this repository.
if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# uv tools
if ! uv tool list 2> /dev/null | grep -F 'trafilatura ' > /dev/null; then
    uv tool install trafilatura
fi

# gh extensions need a logged-in gh.
if gh auth status > /dev/null 2>&1; then
    if ! gh extension list | grep -F 'github/gh-stack' > /dev/null; then
        gh extension install github/gh-stack
    fi
else
    echo "bootstrap: run 'gh auth login', then 'mise bootstrap' again to install gh extensions" >&2
fi

# Work only: mise cannot evaluate this cask (its `postflight_steps` stanza is unsupported),
# so it is installed with brew. mise passes the active profile in MISE_ENV.
case ",${MISE_ENV:-}," in
    *,work,*)
        if ! brew list --cask lstk > /dev/null 2>&1; then
            brew install --cask localstack/tap/lstk
        fi
        ;;
    *,personal,*) ;;
    *)
        echo "bootstrap: expected active mise profile work or personal, got ${MISE_ENV:-unset}" >&2
        exit 1
        ;;
esac
