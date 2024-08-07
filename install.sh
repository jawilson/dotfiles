#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

dotfiles_opts=(-R $script_dir -s --force)

# Handle various arguments that could be passed into the script
while [[ $# -gt 0 ]]; do
    case "$1" in
        *)
            echo "Unknown argument: $1"
            shift
            ;;
    esac
done

# Setup ZSH if necessary
if ! command -v zsh &> /dev/null; then
    if [[ "$MSYSTEM" = "MSYS" ]]; then
        echo "MSYS such as Git Bash not yet supported"
    else
        os_id=$(grep -Po "(?<=^ID=).+" /etc/os-release | sed 's/"//g')
        os_id_like=$(grep -Po "(?<=^ID_LIKE=).+" /etc/os-release | sed 's/"//g')

        if [[ "$os_id" = *"debian"* ]] || [[ "$os_id_like" = *"debian"* ]]; then
            sudo apt-get update -q
            sudo apt-get install -qy zsh
        fi
    fi
fi

# Auto-configure ZSH and OMZ
if command -v zsh &> /dev/null; then
    if [[ "$SHELL" != *"/zsh" ]]; then
        echo "Changing default shell to ZSH"
        sudo chsh -s "$(which zsh)" "$(id -un)"
    fi

    # Set up OMZ if necessary
    if [ ! -d "$ZSH" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

# Set up env files
./tools/dotfiles/bin/dotfiles "${dotfiles_opts[@]}"

# Windows (Git Bash) specific setup
if [[ "$MSYSTEM" = "MSYS" ]]; then
    # Install scoop
    if !command -v scoop &> /dev/null; then
        powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        powershell -Command "irm get.scoop.sh | iex"
    fi
fi

# WSL2 specific setup
if [[ -e "/proc/sys/fs/binfmt_misc/WSLInterop" ]]; then
    if !command -v socat &> /dev/null || !command -v unzip &> /dev/null; then
        sudo apt-get update -q
        sudo apt-get install -qy socat
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
