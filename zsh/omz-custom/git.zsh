# Git Bash
if (( IS_WINDOWS_NATIVE )); then
    export PATH="/c/Windows/System32/OpenSSH:$PATH"
    bindkey "\033[1~" beginning-of-line
    bindkey "\033[4~" end-of-line
fi

# Aliases
alias gdiff='git diff --no-index'
alias gitroot='cd "$(git rev-parse --show-toplevel)"'
alias gbdag='git fetch -p && for branch in $(git for-each-ref --format "%(refname) %(upstream:track)" refs/heads | awk '\''$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'\'' | tr "\n" " "); do git branch -D $branch; done'
alias gcfb='f() { [ "$2" ] && BASE=$2 || BASE=origin/$(git_main_branch) && git cfb $1 $BASE; }; f'
alias gpram='git pull --rebase --autostash origin $(git_main_branch)'
alias gpo='git push origin'
alias graa='git rebase --autostash --autosquash'
alias graam='git rebase --autostash --autosquash origin/$(git_main_branch)'
alias graad='git rebase --autostash --autosquash origin/develop'

# gwtcd <branch>: cd into the worktree that has <branch> checked out.
# Print "branch<TAB>path" for each worktree of the current repo that has a branch checked out.
_gwtcd_worktrees() {
    local line wt_path
    for line in "${(@f)$(git worktree list --porcelain 2>/dev/null)}"; do
        case $line in
            "worktree "*) wt_path=${line#worktree } ;;
            "branch refs/heads/"*) print -r -- "${line#branch refs/heads/}"$'\t'"$wt_path" ;;
        esac
    done
}

gwtcd() {
    if (( $# != 1 )); then
        print -u2 "usage: gwtcd <branch>"
        return 2
    fi
    local line wt_path
    for line in "${(@f)$(_gwtcd_worktrees)}"; do
        if [[ ${line%%$'\t'*} == $1 ]]; then
            wt_path=${line#*$'\t'}
            break
        fi
    done
    if [[ -z $wt_path ]]; then
        print -u2 "gwtcd: no worktree for branch '$1'"
        return 1
    fi
    cd -- "$wt_path"
}

_gwtcd() {
    local line
    local -A worktrees
    for line in "${(@f)$(_gwtcd_worktrees)}"; do
        [[ -n $line ]] && worktrees[${line%%$'\t'*}]=${line#*$'\t'}
    done
    (( CURRENT == 2 )) && _wanted branches expl 'branch with worktree' compadd -k worktrees
}
(( $+functions[compdef] )) && compdef _gwtcd gwtcd
