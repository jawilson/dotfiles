#!/usr/bin/env sh

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Setup ZSH if necessary
if ! command -v zsh &> /dev/null; then
    if [ "$(uname -s)" = "*MSYS*" ]; then
        echo "MSYS such as Git Bash not yet supported"
    else
        OS_ID=$(grep -Po "(?<=^ID=).+" /etc/os-release | sed 's/"//g')
        OS_ID_LIKE=$(grep -Po "(?<=^ID_LIKE=).+" /etc/os-release | sed 's/"//g')

        if [[ "$OS_ID" = *"deian"* ]]; then
            sudo apt-get update -q
            sudo apt-get install -qy zsh
        fi
    fi
fi

# Auto-configure ZSH and OMZ
if command -v zsh &> /dev/null; then
    sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

    # Set up OMZ if necessary
    if [ ! -d "$ZSH" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
fi

# Set up env files
python $SCRIPT_DIR/tools/dotfiles/bin/dotfiles -R $SCRIPT_DIR -s $@

# Auto-configure work profile on Codespaces
if [[ $GITHUB_REPOSITORY = "blinemedical/"* ]]; then
    mv $HOME/.zshrc-work $HOME/.zshrc
fi
