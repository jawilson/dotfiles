# Git Bash
if [[ "$MSYSTEM" = "MSYS" ]]; then
    export PATH="/c/Windows/System32/OpenSSH:$PATH"
    bindkey "\033[1~" beginning-of-line
    bindkey "\033[4~" end-of-line
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    export GITHUB_TOKEN=$(security find-generic-password -w -a $LOGNAME -s "GitHub PAT")
fi
