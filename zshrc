if [ -n "${ZSH_DEBUGRC+1}" ]; then
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
    zmodload zsh/zprof
fi

CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
[[ -d $CACHE_HOME ]] || mkdir -p $CACHE_HOME

# Terminal context flags used for VS Code and agent-specific behavior.
typeset -gi IS_VSCODE_TERMINAL=0
[[ "${TERM_PROGRAM:-}" == "vscode" ]] && IS_VSCODE_TERMINAL=1
typeset -gi IS_AI_AGENT_TERMINAL=0
[[ -n "${AI_AGENT:-}" ]] && IS_AI_AGENT_TERMINAL=1

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if (( !IS_AI_AGENT_TERMINAL )) && [[ -r "${CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOTFILES_DIR=${${(%):-%x}:A:h}
source "$DOTFILES_DIR/tools/common.sh"

typeset -gi IS_WINDOWS_NATIVE=0
is_windows_native && IS_WINDOWS_NATIVE=1

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/base16-default.dark.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

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

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
if (( IS_AI_AGENT_TERMINAL )); then
    ZSH_THEME="robbyrussell"
else
    ZSH_THEME="powerlevel10k/powerlevel10k"
fi

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
if (( IS_AI_AGENT_TERMINAL )); then
    COMPLETION_WAITING_DOTS="false"
else
    COMPLETION_WAITING_DOTS="true"
fi

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
if (( IS_AI_AGENT_TERMINAL )); then
    # Keep agent terminals predictable and fast.
    plugins=()
else
    plugins=(cp debian pip sudo systemd colorize docker docker-compose node aws zsh-autosuggestions)
    plugins+=(git gitfast git-extras fnm zsh-better-npm-completion gh deno fnm dvm)
fi

# User configuration

# Plugin configs
zstyle ':omz:plugins:fnm' autostart yes

# Use coreutils on MacOS
if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
fi

if [ -d /usr/local/opt/python/libexec/bin ]; then
    export PATH="/usr/local/opt/python/libexec/bin:$PATH"
fi

# Add user paths before sourcing omzsh so that they are available to plugins and the prompt
[[ -d $HOME/.bin ]] && export PATH="$HOME/.bin:$PATH"
[[ -d $HOME/.local/bin ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d $HOME/scoop/shims ]] && export PATH="$HOME/scoop/shims:$PATH"
[[ -d $HOME/.fnm ]] && export PATH=$HOME/.fnm:$PATH

# Oh-my-zsh
source $ZSH/oh-my-zsh.sh

# To customize prompt, run `omz theme set <theme-name>`.
if (( IS_AI_AGENT_TERMINAL )); then
    PROMPT='%~ %# '
    RPROMPT=''
else
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
fi

# Default editor
export EDITOR='vim'

# Get colors for tools
dircolors_cache="${CACHE_HOME}/dircolors-${(%):-%n}.zsh"
if [[ -r "$dircolors_cache" ]]; then
    source "$dircolors_cache"
else
    dircolors > "$dircolors_cache"
    source "$dircolors_cache"
fi

# Android setup
if [[ "$ENABLE_ANDROID_SETUP" == "true" ]]; then
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
fi

if [ -d /Applications/Postgres.app/Contents/Versions/latest/bin ]; then
    export PATH=/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH
fi

if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

if [ -f "$HOME/.dvm/bin/dvm" ]; then
    export PATH="$HOME/.dvm/bin:$PATH"
fi

# Check for Python and set user scripts directory
PYTHON=$(get_python_path)
if command -v $PYTHON &> /dev/null; then
    if [[ "$OSTYPE" == darwin* ]]; then
        user_scheme="osx_framework_user"
    elif (( IS_WINDOWS_NATIVE )); then
        user_scheme="nt_user"
    else
        user_scheme="posix_user"
    fi
    python_scripts=$($PYTHON -c "from sysconfig import get_path; print(get_path('scripts', '$user_scheme'), end='')" 2>/dev/null)
    unset user_scheme

    if (( IS_WINDOWS_NATIVE )); then
        python_scripts=$(cygpath -u "$python_scripts")
    fi

    if [[ -d $python_scripts ]]; then
        export PATH="$python_scripts:$PATH"
    fi
    unset python_scripts
fi

# WSL2 specific setup
if [[ -e "/proc/sys/fs/binfmt_misc/WSLInterop" ]]; then
    if (( !IS_VSCODE_TERMINAL && !IS_AI_AGENT_TERMINAL )); then
        # Keep the current path
        keep_current_path() {
            printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"
        }
        precmd_functions+=(keep_current_path)
  fi
fi

# Windows-native specific setup
if (( IS_WINDOWS_NATIVE )); then
    if (( !IS_VSCODE_TERMINAL && !IS_AI_AGENT_TERMINAL )); then
        # Keep the current path
        keep_current_path() {
            printf "\e]9;9;%s\e\\" "$(cygpath -w "$PWD" -C ANSI)"
        }
        precmd_functions+=(keep_current_path)
        typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS:#load})
    fi
fi

# VS Code shell integration should be sourced near the end of ~/.zshrc.
if (( IS_VSCODE_TERMINAL )); then
    vscode_shell_integration_path="$(code --locate-shell-integration-path zsh 2>/dev/null)"
    if [[ -n "$vscode_shell_integration_path" ]]; then
        if (( IS_WINDOWS_NATIVE )) && command -v cygpath &> /dev/null; then
            vscode_shell_integration_path="$(cygpath -u "$vscode_shell_integration_path")"
        fi
        [[ -r "$vscode_shell_integration_path" ]] && . "$vscode_shell_integration_path"
    fi
    unset vscode_shell_integration_path
fi

if [ -n "${ZSH_DEBUGRC+1}" ]; then
    zprof
fi
