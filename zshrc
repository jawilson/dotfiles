# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel9k/powerlevel9k"

# powerlevel9k config
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time context dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status history background_jobs load)

POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_SHORTEN_DELIMITER=""
POWERLEVEL9K_SHORTEN_STRATEGY=truncate_from_right

POWERLEVEL9K_STATUS_VERBOSE=false

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/base16-default.dark.sh"
[[ -s $BASE16_SHELL ]] && source $BASE16_SHELL

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
plugins=(git git-extras cp debian pip sudo systemd colorize docker docker-compose zsh-autosuggestions)

export NVM_LAZY_LOAD=true
plugins+=(zsh-nvm zsh-better-npm-completion)

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

# Oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Enable SSH agent forwarding
zstyle :omz:plugins:ssh-agent agent-forwarding on

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
fi
if [ -d ${HOME}/Library/Android/sdk ]; then
    export ANDROID_SDK=${HOME}/Library/Android/sdk
fi
if [ -d /opt/android-sdk ]; then
    export ANDROID_SDK=/opt/android-sdk
fi
if [ -n "$ANDROID_SDK" ] && [ -d "$ANDROID_SDK" ]; then
    export PATH=$ANDROID_SDK/tools:$PATH
    export PATH=$ANDROID_SDK/platform-tools:$PATH
fi

# added by travis gem
[ -f /Users/jawilson/.travis/travis.sh ] && source /Users/jawilson/.travis/travis.sh

PATH="/Users/jawilson/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/Users/jawilson/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/Users/jawilson/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/Users/jawilson/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/Users/jawilson/perl5"; export PERL_MM_OPT;

if [ -d/Applications/Postgres.app/Contents/Versions/latest/bin ]; then
    export PATH=/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH
fi
