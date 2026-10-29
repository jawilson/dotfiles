#!/usr/bin/env bash
# Installs what `mise bootstrap` cannot install for itself, records the
# profile, then runs `mise bootstrap`. Everything else lives in mise*.toml.
# Usage: ./install.sh [--profile work|personal] [--no-run-zsh]

#region Script setup

# Get script directory with fallback if dirname isn't available
if command -v dirname &> /dev/null; then
    script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
else
    script_dir=$( cd -- "${BASH_SOURCE[0]%/*}" &> /dev/null && pwd )
fi

# shellcheck disable=SC1091
source "${script_dir}/tools/common.sh"

profile=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            if [[ $# -lt 2 || ( "$2" != work && "$2" != personal ) ]]; then
                echo "Error: --profile requires work or personal."
                exit 1
            fi
            profile="$2"
            shift 2
            ;;
        --no-run-zsh)
            # Do not start zsh after setup
            RUNZSH=no
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            shift
            ;;
    esac
done

# Only default to "yes" for RUNZSH if in interactive mode
if [ -t 0 ]; then
    # Terminal is interactive
    RUNZSH=${RUNZSH:-yes}
else
    # Non-interactive mode
    RUNZSH=${RUNZSH:-no}
fi

#endregion

# The profile selects mise.<profile>.toml; .miserc.local.toml keeps it for later runs.
miserc_local="${script_dir}/.miserc.local.toml"
if [ -z "$profile" ] && [ -f "$miserc_local" ]; then
    profile=$(sed -n 's/^env = \["\(.*\)"\]$/\1/p' "$miserc_local")
fi
if [ -z "$profile" ] && [ -t 0 ]; then
    read -r -p "Profile (work or personal): " profile
fi
case "$profile" in
    work|personal) ;;
    *)
        echo "Error: choose a profile with --profile work or --profile personal."
        exit 1
        ;;
esac
printf 'env = ["%s"]\n' "$profile" > "$miserc_local" || exit 1

#region Prerequisites mise cannot install itself

if is_windows_native; then
    if [ -n "$LOCALAPPDATA" ]; then
        winget_links=$(cygpath -u "$LOCALAPPDATA/Microsoft/WinGet/Links" 2>/dev/null || echo "$LOCALAPPDATA/Microsoft/WinGet/Links")
        export PATH="$winget_links:$PATH"
    fi
    export PATH="$HOME/AppData/Local/Microsoft/WinGet/Links:$HOME/.local/bin:$HOME/scoop/shims:$PATH"

    if ! command -v mise &> /dev/null; then
        winget_cmd="winget"
        command -v winget &> /dev/null || winget_cmd="winget.exe"
        "$winget_cmd" install --id jdx.mise -e --accept-source-agreements --accept-package-agreements || "$winget_cmd" install jdx.mise || exit 1
        hash -r 2>/dev/null || true
    fi
else
    export PATH="$HOME/.local/bin:$PATH"
fi

if is_macos; then
    if ! command -v brew &> /dev/null && [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /usr/local/bin/brew ]; then
        brew_installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) || exit 1
        /bin/bash -c "$brew_installer" || exit 1
    fi

    # The installer cannot change this shell's PATH, so look for brew by path.
    if [ -x /opt/homebrew/bin/brew ]; then
        brew_env=$(/opt/homebrew/bin/brew shellenv) || exit 1
    elif [ -x /usr/local/bin/brew ]; then
        brew_env=$(/usr/local/bin/brew shellenv) || exit 1
    else
        echo "Error: Homebrew is not installed."
        exit 1
    fi
    eval "$brew_env" || exit 1
fi

if command -v apt-get &> /dev/null; then
    sudo apt-get update -q || exit 1
    sudo apt-get install -qy curl ca-certificates || exit 1
fi

if ! is_windows_native && ! command -v mise &> /dev/null; then
    curl -fsSL https://mise.run | sh || exit 1
fi

if ! command -v mise &> /dev/null; then
    echo "Error: mise is not installed and could not be installed automatically."
    echo "Please install mise manually (https://mise.jdx.dev/installing-mise.html) and re-run this script."
    exit 1
fi

#endregion

# Run from the repository: .miserc.toml and .miserc.local.toml (platform and profile
# files) are read only from the working directory, not through `mise -C`.
(
    cd "$script_dir" || exit 1
    mise trust ./mise.toml || exit 1
    mise -E "$profile" bootstrap --yes --force-dotfiles --skip-dirty
) || exit 1

ZSH=${ZSH:-$HOME/.oh-my-zsh}

# Run zsh if available and configured
if [[ "$RUNZSH" = "yes" ]] && command -v zsh &> /dev/null && [ -f "$ZSH/oh-my-zsh.sh" ]; then
    echo "ZSH and Oh My Zsh are configured."

    current_shell="${SHELL:-}"
    current_shell_name="${current_shell##*/}"
    current_proc="$(ps -o comm= -p $$ 2>/dev/null | tr -d '[:space:]')"
    parent_proc="$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d '[:space:]')"

    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$current_shell_name" == "zsh" ]] || [[ "$current_proc" == "zsh" ]] || [[ "$parent_proc" == "zsh" ]]; then
        echo "Open a new ZSH session to load the updated configuration."
        # shellcheck disable=SC2317
        return 0 2>/dev/null || exit 0
    fi

    echo "Starting a new login ZSH session..."
    exec zsh -l
fi
