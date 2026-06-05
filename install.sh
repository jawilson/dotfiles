#!/usr/bin/env bash

#region Script setup and argument parsing

# Get script directory with fallback if dirname isn't available
if command -v dirname &> /dev/null; then
    script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
else
    script_dir=$( cd -- "${BASH_SOURCE[0]%/*}" &> /dev/null && pwd )
fi

dotfiles_opts=(-R $script_dir -s --force)

is_windows_native() {
    case "$(uname -s 2>/dev/null)" in
        CYGWIN*|MINGW*|MSYS*) return 0 ;;
        *) return 1 ;;
    esac
}

source "${script_dir}/tools/common.sh"
source "${script_dir}/tools/install/link_powershell_profile.sh"

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

#endregion

#region System Pre-requisites

# Windows native shell specific setup
export PATH="$HOME/scoop/shims:$PATH"
if is_windows_native; then
    # Install scoop
    if ! command -v scoop &> /dev/null; then
        powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072"
        powershell -Command 'iex "& {$(irm get.scoop.sh)} -RunAsAdmin"'
    fi
fi

if command apt-get &> /dev/null; then
    # Update package lists
    sudo apt-get update -q
fi

# Setup ZSH if necessary
if ! command -v zsh &> /dev/null; then
    if is_windows_native; then
        if command -v pacman &> /dev/null; then
            pacman --noconfirm -S zsh
        else
            echo "Error: ZSH is not installed and cannot be installed automatically on native Windows without a supported package manager."
            echo "Please install ZSH manually (e.g. via Chocolatey or Scoop) and re-run this script."
            exit 1
        fi
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

PYTHON=$(get_python_path)
if [ -z "$PYTHON" ]; then
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -qy python3
    elif command -v dnf &> /dev/null; then
        sudo dnf install -qy python3
    elif command -v yum &> /dev/null; then
        sudo yum install -qy python3
    elif command -v choco &> /dev/null; then
        choco install -y python3
    elif command -v scoop &> /dev/null; then
        scoop install python
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm python
    fi
    PYTHON=$(get_python_path)
fi
if [ -z "$PYTHON" ]; then
    echo "Error: Python is not installed and could not be installed automatically."
    echo "Please install Python manually and re-run this script."
    exit 1
fi

# Auto-configure ZSH and OMZ
if command -v zsh &> /dev/null; then
    if ! is_windows_native && [[ "$SHELL" != *"/zsh" ]]; then
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

#endregion

# Set up the dotfiles
if [ -n "$PYTHON" ]; then
    $PYTHON "${script_dir}/tools/dotfiles/bin/dotfiles" "${dotfiles_opts[@]}"
else
    echo "Warning: No Python installation detected, cannot install dotfiles"
    exit 1
fi

#region Post-setup configuration

# Native Windows specific setup
if is_windows_native; then
    # Link PowerShell profile (non-Windows gets this for free via .config/powershell/Microsoft.PowerShell_profile.ps1)
    pwsh_profile_source="${script_dir}/config/powershell/Microsoft.PowerShell_profile.ps1"
    if command -v powershell.exe &> /dev/null; then
        link_powershell_profile powershell.exe "$pwsh_profile_source"
    fi
    if command -v pwsh.exe &> /dev/null; then
        link_powershell_profile pwsh.exe "$pwsh_profile_source"
    fi

    # Setup cmdrc
    cmdrc_source="${HOME}/.cmdrc.bat"
    cmdrc_source_windows="$cmdrc_source"
    if command -v cygpath &> /dev/null; then
        cmdrc_source_windows=$(cygpath -w "$cmdrc_source")
    fi

    if command -v reg.exe &> /dev/null; then
        if ! MSYS2_ARG_CONV_EXCL='*' reg.exe add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "$cmdrc_source_windows" /f > /dev/null; then
            echo "Warning: Failed to set HKCU\\Software\\Microsoft\\Command Processor\\AutoRun."
        fi
    else
        echo "Warning: reg.exe not found; skipping cmd AutoRun registry configuration."
    fi
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
    if is_windows_native; then
        scoop install fnm
    else
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$FNM_DIR"
    fi
fi

#endregion

# Run zsh if available and configured
if [[ "$RUNZSH" = "yes" ]] && command -v zsh &> /dev/null && [ -f "$ZSH/oh-my-zsh.sh" ]; then
    echo "ZSH and Oh My Zsh are configured. Starting ZSH..."
    exec zsh -l
fi
