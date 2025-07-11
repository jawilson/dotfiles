#!/usr/bin/env bash

# Get script directory with fallback if dirname isn't available
if command -v dirname &> /dev/null; then
    script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
else
    script_dir=$( cd -- "${BASH_SOURCE[0]%/*}" &> /dev/null && pwd )
fi

dotfiles_opts=(-R $script_dir -s --force)

# Handle various arguments that could be passed into the script
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-run-zsh)
            # Run ZSH after setup
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

##
# Install pre-requisites and tools
##

# Windows (Git Bash) specific setup
if [[ "$MSYSTEM" = "MSYS" ]]; then
    # Install scoop
    if ! command -v scoop &> /dev/null; then
        powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        powershell -Command "irm get.scoop.sh | iex"
    fi
fi

if command apt-get &> /dev/null; then
    # Update package lists
    sudo apt-get update -q
fi

# Setup ZSH if necessary
if ! command -v zsh &> /dev/null; then
    if [[ "$MSYSTEM" = "MSYS" ]]; then
        echo "MSYS such as Git Bash not yet supported"
    else
        os_id=$(grep -Po "(?<=^ID=).+" /etc/os-release | sed 's/"//g')
        os_id_like=$(grep -Po "(?<=^ID_LIKE=).+" /etc/os-release | sed 's/"//g')

        if [[ "$os_id" = *"debian"* ]] || [[ "$os_id_like" = *"debian"* ]]; then
            sudo apt-get install -qy zsh
        fi
    fi

    if ! command -v zsh &> /dev/null; then
        echo "Error: ZSH is not installed and could not be installed automatically."
        echo "Please install ZSH manually and re-run this script."
        exit 1
    fi
fi

PYTHON_PATH=$(command -v python3 || command -v python2 || command -v python || echo "")
if [ -z "$PYTHON_PATH" ]; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -q
        sudo apt-get install -qy python3
        PYTHON_PATH=$(command -v python3)
    elif command -v dnf &> /dev/null; then
        sudo dnf install -qy python3
        PYTHON_PATH=$(command -v python3)
    elif command -v yum &> /dev/null; then
        sudo yum install -qy python3
        PYTHON_PATH=$(command -v python3)
    elif command -v scoop &> /dev/null; then
        scoop install python
        PYTHON_PATH=$(command -v python)
    fi
fi
if [ -z "$PYTHON_PATH" ]; then
    echo "Error: Python is not installed and could not be installed automatically."
    echo "Please install Python manually and re-run this script."
    exit 1
fi

# Auto-configure ZSH and OMZ
if command -v zsh &> /dev/null; then
    if [[ "$SHELL" != *"/zsh" ]]; then
        echo "Changing default shell to ZSH"
        sudo chsh -s "$(which zsh)" "$(id -un)"
    fi

    ZSH=${ZSH:-$HOME/.oh-my-zsh}
    # Set up OMZ if necessary
    if [ ! -f "$ZSH/oh-my-zsh.sh" ]; then
        # If $ZSH exists, remove it
        if [ -d "$ZSH" ]; then
            echo "Removing existing \$ZSH directory"
            rm -rf "$HOME/.oh-my-zsh"
        fi
        if ! command -v curl &> /dev/null; then
            sudo apt-get install -qy curl
        fi
        ZSH=$ZSH CHSH=no RUNZSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

# Set up the dotfiles
if [ -n "$PYTHON_PATH" ]; then
    $PYTHON_PATH "${script_dir}/tools/dotfiles/bin/dotfiles" "${dotfiles_opts[@]}"
else
    echo "Warning: No Python installation detected, cannot install dotfiles"
    exit 1
fi

# WSL2 specific setup
if [[ -e "/proc/sys/fs/binfmt_misc/WSLInterop" ]]; then
    if ! command -v socat &> /dev/null || ! command -v unzip &> /dev/null || ! command -v curl &> /dev/null; then
        sudo apt-get install -qy socat unzip curl
    fi

    # Install npiperelay
    if [[ -z "$NPIPERELAY" ]]; then
        userprofile=`wslpath $(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d "\r")`
        mkdir $userprofile/bin
        curl -fsSL https://github.com/jstarks/npiperelay/releases/latest/download/npiperelay_windows_amd64.zip -o /tmp/npiperelay.zip && unzip -o /tmp/npiperelay.zip npiperelay.exe -d $userprofile/bin && chmod +x $userprofile/bin/npiperelay.exe
        rm -rf /tmp/npiperelay.zip
        cmd.exe /c "setx NPIPERELAY %USERPROFILE%\\bin\\npiperelay.exe"
        win_wslenv=$(cmd.exe /c "echo %WSLENV%" 2>/dev/null | tr -d "\r")
        if [ "$win_wslenv" != "*NPIPERELAY/p*" ]; then
            cmd.exe /c "setx WSLENV \"${win_wslenv:+${win_wslenv}:}NPIPERELAY/p\""
        fi
    fi
fi

# Codespaces specific setup
if [ -n "$CODESPACES" ]; then
  if [ -n "$GH_PACKAGE_REGISTRY_TOKEN" ]; then
    echo "//npm.pkg.github.com/:_authToken=$GH_PACKAGE_REGISTRY_TOKEN" >> ~/.npmrc
  fi
fi

# fnm
FNM_DIR="$HOME/.fnm"
if ! command -v $FNM_DIR/fnm &>/dev/null; then
    if [[ "$MSYSTEM" == "MSYS" ]]; then
        scoop install fnm
    else
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$FNM_DIR"
    fi
fi

# Run zsh if available and configured
if [[ "$RUNZSH" = "yes" ]] && command -v zsh &> /dev/null && [ -f "$ZSH/oh-my-zsh.sh" ]; then
    echo "ZSH and Oh My Zsh are configured. Starting ZSH..."
    exec zsh -l
fi
