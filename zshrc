# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/base16-default.dark.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

DISABLE_BITWARDEN_SETUP="true"

# fnm
if [[ "$MSYSTEM" != "MSYS" ]]; then
    export PATH=$HOME/.fnm:$PATH
    if (( ! $+commands[fnm] )); then
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir "$HOME/.fnm"
    fi
    eval "`fnm env --use-on-cd`"
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOTFILES_DIR=${${(%):-%x}:A:h}

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="powerlevel10k/powerlevel10k"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Used for some OHZsh themes to determine if user@host should be printed
export DEFAULT_USER=jawilson

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Highlight all available matches
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor root)

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$HOME/.oh-my-zsh/dotfiles-custom

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git git-extras cp debian pip sudo systemd colorize docker docker-compose node aws zsh-autosuggestions)
plugins+=(fnm zsh-better-npm-completion gh)

# User configuration

# Use coreutils on MacOS
if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
fi

if [ -d /usr/local/opt/python/libexec/bin ]; then
    export PATH="/usr/local/opt/python/libexec/bin:$PATH"
fi

# Add user bin directory
[[ -d $HOME/.bin ]] && export PATH="$HOME/.bin:$PATH"
[[ -d $HOME/.local/bin ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d $HOME/scoop/shims ]] && export PATH="$HOME/scoop/shims:$PATH"

# Enable SSH agent forwarding
if [[ ! -e "/proc/sys/fs/binfmt_misc/WSLInterop" ]]; then
    zstyle :omz:plugins:ssh-agent agent-forwarding on
elif [[ -n "$NPIPERELAY" ]]; then
    export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
    ss -a | grep -q $SSH_AUTH_SOCK
    if [ $? -ne 0 ]; then
        rm -f $SSH_AUTH_SOCK
        ( setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"${NPIPERELAY} -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
    fi
else
    >&2 echo "NPIPERELAY environment variable not set, unable to configure SSH agent forwarding"
fi

# Oh-my-zsh
source $ZSH/oh-my-zsh.sh

# nvm (for VS Code)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Default editor
export EDITOR='vim'

# Get colors for tools
eval $(dircolors)

# Android setup
if [ -d /opt/android-ndk ]; then
    export ANDROID_NDK=/opt/android-ndk
    export PATH=$ANDROID_NDK:$PATH
fi
if [ -d ${HOME}/Android/Sdk ]; then
    export ANDROID_SDK=${HOME}/Android/Sdk
elif [ -d ${HOME}/Library/Android/sdk ]; then
    export ANDROID_SDK=${HOME}/Library/Android/sdk
elif [ -d /opt/android-sdk ]; then
    export ANDROID_SDK=/opt/android-sdk
fi
if [ -n "$ANDROID_SDK" ] && [ -d "$ANDROID_SDK" ]; then
    export PATH=$ANDROID_SDK/tools:$PATH
    export PATH=$ANDROID_SDK/platform-tools:$PATH
    export PATH=$ANDROID_SDK/cmdline-tools/latest/bin:$PATH
fi

if [ -d /Applications/Postgres.app/Contents/Versions/latest/bin ]; then
    export PATH=/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH
fi

if [ -d "$HOME/.cargo" ]; then
    source "$HOME/.cargo/env"
fi
