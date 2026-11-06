# Startup update check for the dotfiles repository.
# Sourced by zsh/zshrc before the Powerlevel10k instant prompt preamble.

() {
    emulate -L zsh
    setopt extendedglob

    local update_mode epoch_target local_changes_mode dot_apply_mode bootstrap_mode

    if [[ -n "${DOTFILES_UPDATE_MODE:-}" ]]; then
        update_mode="$DOTFILES_UPDATE_MODE"
    else
        zstyle -s ':dotfiles:update' mode update_mode || update_mode=auto
    fi

    if [[ "${DOTFILES_UPDATE_DAYS:-}" == <-> ]]; then
        epoch_target="$DOTFILES_UPDATE_DAYS"
    else
        zstyle -s ':dotfiles:update' frequency epoch_target || epoch_target=1
        [[ "$epoch_target" == <-> ]] || epoch_target=1
    fi

    if [[ -n "${DOTFILES_UPDATE_LOCAL_CHANGES:-}" ]]; then
        local_changes_mode="$DOTFILES_UPDATE_LOCAL_CHANGES"
    else
        zstyle -s ':dotfiles:update' local-changes local_changes_mode || local_changes_mode=prompt
    fi

    if [[ -n "${DOTFILES_UPDATE_DOT_APPLY:-}" ]]; then
        dot_apply_mode="$DOTFILES_UPDATE_DOT_APPLY"
    else
        zstyle -s ':dotfiles:update' dot-apply dot_apply_mode || dot_apply_mode=auto
    fi

    if [[ -n "${DOTFILES_UPDATE_BOOTSTRAP:-}" ]]; then
        bootstrap_mode="$DOTFILES_UPDATE_BOOTSTRAP"
    else
        zstyle -s ':dotfiles:update' bootstrap bootstrap_mode || bootstrap_mode=auto
    fi

    # Zero-fork fast-path exit
    if [[ "$update_mode" == disabled ]]; then
        return 0
    fi
    if (( ${IS_AI_AGENT_TERMINAL:-0} )); then
        return 0
    fi
    if [[ ! -o interactive ]]; then
        return 0
    fi
    if [[ ! -t 0 || ! -t 1 ]] && [[ -z "${DOTFILES_UPDATE_MODE:-}" ]]; then
        return 0
    fi
    if [[ -z "${DOTFILES_DIR:-}" || ! -w "$DOTFILES_DIR" ]]; then
        return 0
    fi

    zmodload zsh/datetime 2>/dev/null || return 0
    local current_day=$(( EPOCHSECONDS / 86400 ))
    local cache_dir="${CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}}"
    local state_file="$cache_dir/dotfiles-update"
    local LAST_EPOCH

    if [[ -r "$state_file" ]]; then
        source "$state_file" 2>/dev/null
        if [[ "${LAST_EPOCH:-}" == <-> ]] && (( (current_day - LAST_EPOCH) < epoch_target )); then
            return 0
        fi
    fi

    # Acquire lock directory
    zmodload -F zsh/stat b:zstat 2>/dev/null || return 0
    local lock_dir="$cache_dir/dotfiles-update.lock"
    local -a stat_info
    if zstat -A stat_info +mtime "$lock_dir" 2>/dev/null; then
        if (( (stat_info[1] + 86400) < EPOCHSECONDS )); then
            command rm -rf "$lock_dir" 2>/dev/null
        fi
    fi
    command mkdir -p "$cache_dir" 2>/dev/null
    command mkdir "$lock_dir" 2>/dev/null || return 0

    {
        # Re-read state file inside lock in case a concurrent shell just checked
        if [[ -r "$state_file" ]]; then
            LAST_EPOCH=
            source "$state_file" 2>/dev/null
            if [[ "${LAST_EPOCH:-}" == <-> ]] && (( (current_day - LAST_EPOCH) < epoch_target )); then
                return 0
            fi
        fi

        (( $+commands[git] )) || return 0
        git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

        local branch remote merge_ref remote_branch remote_url local_head
        branch=$(git -C "$DOTFILES_DIR" symbolic-ref --quiet --short HEAD 2>/dev/null) || return 0
        remote=$(git -C "$DOTFILES_DIR" config --get "branch.${branch}.remote" 2>/dev/null)
        merge_ref=$(git -C "$DOTFILES_DIR" config --get "branch.${branch}.merge" 2>/dev/null)
        remote_branch="${merge_ref#refs/heads/}"
        [[ -n "$remote" && -n "$remote_branch" ]] || return 0

        remote_url=$(git -C "$DOTFILES_DIR" config --get "remote.${remote}.url" 2>/dev/null)
        local_head=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null) || return 0

        local remote_head="" checked=0 repo=""

        # GitHub HTTPS SHA fast check (avoids SSH agent prompts when no updates exist)
        case "$remote_url" in
            https://github.com/*)
                repo="${${remote_url#https://github.com/}%.git}"
                ;;
            git@github.com:*)
                repo="${${remote_url#git@github.com:}%.git}"
                ;;
            ssh://git@github.com/*)
                repo="${${remote_url#ssh://git@github.com/}%.git}"
                ;;
        esac

        if [[ -n "$repo" ]] && (( $+commands[curl] )); then
            remote_head=$(curl --connect-timeout 2 --max-time 5 -fsSL \
                -H 'Accept: application/vnd.github.v3.sha' \
                "https://api.github.com/repos/${repo}/commits/${remote_branch}" 2>/dev/null)
            if [[ "$remote_head" == (#i)[0-9a-f](#c40) ]]; then
                checked=1
                if [[ "$remote_head" == "$local_head" ]] || \
                   git -C "$DOTFILES_DIR" merge-base --is-ancestor "$remote_head" "$local_head" 2>/dev/null; then
                    print -r -- "LAST_EPOCH=$current_day" >! "$state_file" 2>/dev/null || true
                    return 0
                fi
            fi
        fi

        # Git fetch fallback
        if (( !checked )); then
            if ! GIT_TERMINAL_PROMPT=0 git -C "$DOTFILES_DIR" fetch --quiet "$remote" "$remote_branch" 2>/dev/null; then
                print -r -- "LAST_EPOCH=$current_day" >! "$state_file" 2>/dev/null || true
                return 0
            fi
            remote_head=$(git -C "$DOTFILES_DIR" rev-parse FETCH_HEAD 2>/dev/null)
            if [[ -z "$remote_head" || "$remote_head" == "$local_head" ]] || \
               git -C "$DOTFILES_DIR" merge-base --is-ancestor "$remote_head" "$local_head" 2>/dev/null; then
                print -r -- "LAST_EPOCH=$current_day" >! "$state_file" 2>/dev/null || true
                return 0
            fi
        fi

        if [[ "$update_mode" == auto ]]; then
            DOTFILES_UPDATE_LOCAL_CHANGES="$local_changes_mode" \
            DOTFILES_UPDATE_DOT_APPLY="$dot_apply_mode" \
            DOTFILES_UPDATE_BOOTSTRAP="$bootstrap_mode" \
                zsh "$DOTFILES_DIR/tools/dotfiles-update.zsh"
            print -r -- "LAST_EPOCH=$current_day" >! "$state_file" 2>/dev/null || true
        elif [[ "$update_mode" == prompt ]]; then
            local typed_input=0 termios
            if [[ -t 0 ]] && zmodload zsh/zselect 2>/dev/null && termios=$(stty -g 2>/dev/null); then
                {
                    stty -icanon 2>/dev/null
                    if zselect -t 0 -r 0 2>/dev/null; then
                        typed_input=1
                    fi
                } always {
                    stty "$termios" 2>/dev/null
                }
            fi

            if (( typed_input )); then
                print -r -- $'\r\e[0K[dotfiles] Updates are available; run '\''dotfiles-update'\'' to update.'
                return 0
            fi

            local option
            printf "[dotfiles] Would you like to update dotfiles? [Y/n] "
            if [[ -t 0 ]]; then
                read -r -k 1 option || option=n
                [[ "$option" == $'\n' ]] || echo
            else
                read -r option || option=n
            fi
            case "$option" in
                [yY$'\n']|$'\r'|"")
                    DOTFILES_UPDATE_LOCAL_CHANGES="$local_changes_mode" \
                    DOTFILES_UPDATE_DOT_APPLY="$dot_apply_mode" \
                    DOTFILES_UPDATE_BOOTSTRAP="$bootstrap_mode" \
                        zsh "$DOTFILES_DIR/tools/dotfiles-update.zsh"
                    print -r -- "LAST_EPOCH=$current_day" >! "$state_file" 2>/dev/null || true
                    ;;
                [nN])
                    print -r -- "LAST_EPOCH=$current_day" >! "$state_file" 2>/dev/null || true
                    print "[dotfiles] You can update manually by running 'dotfiles-update'"
                    ;;
                *)
                    print "[dotfiles] You can update manually by running 'dotfiles-update'"
                    ;;
            esac
        fi
    } always {
        command rm -rf "$lock_dir" 2>/dev/null
    }
}
