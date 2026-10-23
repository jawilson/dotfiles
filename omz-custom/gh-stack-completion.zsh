# gh does not forward completion to extensions, so `gh stack ...` gets nothing from _gh.
# Complete the extension's subcommands and flags by parsing its --help output.
(( $+commands[gh] )) || return

typeset -gA _gh_stack_help_cache

# Print the cached `gh stack [subcommand] --help` text, fetching it on first use.
_gh_stack_help() {
    local key=${1:-root}
    if (( ! $+_gh_stack_help_cache[$key] )); then
        _gh_stack_help_cache[$key]=$(gh stack ${1:+$1} --help 2>/dev/null)
    fi
    print -r -- "${_gh_stack_help_cache[$key]}"
}

# Complete local branch names (checkout also takes stack/PR numbers, which can't be listed offline).
_gh_stack_branches() {
    local -a branches
    branches=("${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)}")
    _wanted branches expl 'branch' compadd -a branches
}

_gh_stack() {
    local line sub=${words[3]} target=root
    local -a cmds specs
    local MATCH MBEGIN MEND
    local -a match

    if (( CURRENT == 3 )) && [[ $PREFIX != -* ]]; then
        for line in "${(@f)$(_gh_stack_help)}"; do
            [[ $line =~ '^  ([a-z][a-z-]*)  +(.+)$' ]] && cmds+=("${match[1]}:${match[2]}")
        done
        _describe -t commands 'gh stack command' cmds
        return
    fi

    # Only trust words[3] as a subcommand if it is listed in the root help.
    if (( CURRENT > 3 )) && [[ -n $sub && $sub != -* ]] && _gh_stack_help | grep -Eq "^  ${sub}  "; then
        target=$sub
    fi

    for line in "${(@f)$(_gh_stack_help ${target#root})}"; do
        if [[ $line =~ '^ +(-[a-zA-Z], )?--([a-z][a-z-]*)( [a-z]+)?  +(.+)$' ]]; then
            local flag=${match[2]} value=${match[3]# } desc=${match[4]//\[/\\[}
            desc=${desc//\]/\\]}
            specs+=("--${flag}[${desc}]${value:+:${value}: }")
        fi
    done
    # Subcommands taking existing branch names; the rest fall back to files.
    local positional=_default
    [[ $target == (checkout|init|rebase|link) ]] && positional=_gh_stack_branches
    _arguments -S $specs "*: :$positional"
}

_gh_with_extensions() {
    if [[ ${words[2]} == stack ]] && (( CURRENT > 2 )); then
        _gh_stack
    else
        _gh "$@"
    fi
}

compdef _gh_with_extensions gh
