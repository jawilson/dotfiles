# Git Bash
if [[ "$MSYSTEM" = "MSYS" ]]; then
    export PATH="/c/Windows/System32/OpenSSH:$PATH"
    bindkey "\033[1~" beginning-of-line
    bindkey "\033[4~" end-of-line
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    export GITHUB_TOKEN=$(security find-generic-password -w -a $LOGNAME -s "GitHub PAT")
fi

# Aliases
alias gdiff='git diff --no-index'
alias gitroot='cd "$(git rev-parse --show-toplevel)"'
alias gbdag='git fetch -p && for branch in $(git for-each-ref --format "%(refname) %(upstream:track)" refs/heads | awk '\''$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'\'' | tr "\n" " "); do git branch -D $branch; done'
alias gcfb='f() { [ "$2" ] && BASE=$2 || BASE=origin/$(git_main_branch) && git cfb $1 $BASE; }; f'
alias gpram='git pull --rebase --autostash origin $(git_main_branch)'
alias gpo='git push origin'
alias graam='git rebase --autostash --autosquash origin/$(git_main_branch)'
alias graad='git rebase --autostash --autosquash origin/develop'
