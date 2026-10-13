#!/usr/bin/env bash
# Imperative macOS setup, run as the `bootstrap` task from mise.macos.toml.
# Every step checks first, so `mise bootstrap` can run it again. Login items are
# LaunchAgents in mise.macos.toml, not steps here.
set -euo pipefail

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
