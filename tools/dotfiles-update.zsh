#!/usr/bin/env zsh
# Standalone updater for the dotfiles repository.
# Executed by tools/check-for-update.zsh on interactive shell startup or manually
# via `dotfiles-update` / `mise run dotfiles:update`.

if [[ "${ZSH_EVAL_CONTEXT:-}" == *:file ]]; then
    print -u2 "error: tools/dotfiles-update.zsh should be executed, not sourced"
    return 1
fi

emulate -L zsh
setopt pipefail extendedglob

zmodload zsh/datetime
zmodload zsh/zselect 2>/dev/null || true

DOTFILES_DIR="${DOTFILES_DIR:-${0:A:h:h}}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
state_file="$CACHE_HOME/dotfiles-update"

check_only=0

while (( $# > 0 )); do
    case "$1" in
        --check)
            check_only=1
            shift
            ;;
        --local-changes)
            if (( $# < 2 )); then
                print -u2 "[dotfiles] error: --local-changes requires an argument (prompt|reapply|discard|abort)"
                exit 2
            fi
            DOTFILES_UPDATE_LOCAL_CHANGES="$2"
            shift 2
            ;;
        --local-changes=*)
            DOTFILES_UPDATE_LOCAL_CHANGES="${1#*=}"
            shift
            ;;
        --dot-apply)
            DOTFILES_UPDATE_DOT_APPLY=always
            shift
            ;;
        --no-dot-apply)
            DOTFILES_UPDATE_DOT_APPLY=never
            shift
            ;;
        --bootstrap)
            DOTFILES_UPDATE_BOOTSTRAP=always
            shift
            ;;
        --no-bootstrap)
            DOTFILES_UPDATE_BOOTSTRAP=never
            shift
            ;;
        -h|--help)
            print "Usage: dotfiles-update [--check] [--local-changes <prompt|reapply|discard|abort>] [--[no-]dot-apply] [--[no-]bootstrap]"
            exit 0
            ;;
        *)
            print -u2 "[dotfiles] error: unknown option: $1"
            exit 2
            ;;
    esac
done

local_changes_mode="${DOTFILES_UPDATE_LOCAL_CHANGES:-prompt}"
case "$local_changes_mode" in
    prompt|reapply|discard|abort) ;;
    *)
        print -u2 "[dotfiles] Warning: Invalid local-changes mode '$local_changes_mode'; falling back to 'prompt'."
        local_changes_mode=prompt
        ;;
esac

dot_apply_mode="${DOTFILES_UPDATE_DOT_APPLY:-auto}"
case "$dot_apply_mode" in
    auto|always|never) ;;
    *)
        print -u2 "[dotfiles] Warning: Invalid dot-apply mode '$dot_apply_mode'; falling back to 'auto'."
        dot_apply_mode=auto
        ;;
esac

bootstrap_mode="${DOTFILES_UPDATE_BOOTSTRAP:-auto}"
case "$bootstrap_mode" in
    auto|always|never) ;;
    *)
        print -u2 "[dotfiles] Warning: Invalid bootstrap mode '$bootstrap_mode'; falling back to 'auto'."
        bootstrap_mode=auto
        ;;
esac

_dotfiles_write_state() {
    mkdir -p "$CACHE_HOME" 2>/dev/null || return 0
    print -r -- "LAST_EPOCH=$(( EPOCHSECONDS / 86400 ))" >! "$state_file" 2>/dev/null || true
}

_dotfiles_find_mise() {
    if [[ -n "${commands[mise]:-}" ]]; then
        print -r -- "${commands[mise]}"
        return 0
    fi

    local -a candidates=(
        "$HOME/.local/bin/mise"
        "$HOME/scoop/shims/mise.exe"
    )
    if [[ -n "${LOCALAPPDATA:-}" ]] && (( $+commands[cygpath] )); then
        candidates+=("$(cygpath -u "$LOCALAPPDATA\\Microsoft\\WinGet\\Links" 2>/dev/null)/mise.exe")
    fi
    candidates+=(
        "/opt/homebrew/bin/mise"
        "/usr/local/bin/mise"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            print -r -- "$candidate"
            return 0
        fi
    done
    return 1
}

if ! command -v git >/dev/null 2>&1 || ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 "[dotfiles] Cannot update: $DOTFILES_DIR is not a git repository."
    exit 1
fi

branch=$(git -C "$DOTFILES_DIR" symbolic-ref --quiet --short HEAD 2>/dev/null) || {
    print -u2 "[dotfiles] Skipping update: repository is on a detached HEAD."
    exit 1
}

remote=$(git -C "$DOTFILES_DIR" config --get "branch.${branch}.remote" 2>/dev/null)
merge_ref=$(git -C "$DOTFILES_DIR" config --get "branch.${branch}.merge" 2>/dev/null)
remote_branch="${merge_ref#refs/heads/}"

if [[ -z "$remote" || -z "$remote_branch" ]]; then
    print -u2 "[dotfiles] Skipping update: branch '$branch' has no upstream configured."
    exit 1
fi

old_head=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null) || exit 1

if ! GIT_TERMINAL_PROMPT=0 git -C "$DOTFILES_DIR" fetch --quiet "$remote" "$remote_branch"; then
    print -u2 "[dotfiles] Error: Failed to fetch from '$remote/$remote_branch'."
    exit 1
fi

remote_head=$(git -C "$DOTFILES_DIR" rev-parse FETCH_HEAD 2>/dev/null) || exit 1

if [[ "$old_head" == "$remote_head" ]] || git -C "$DOTFILES_DIR" merge-base --is-ancestor "$remote_head" "$old_head" 2>/dev/null; then
    if (( check_only )); then
        exit 1
    fi
    _dotfiles_write_state
    print "[dotfiles] Already up to date."
    if [[ "$dot_apply_mode" != always && "$bootstrap_mode" != always ]]; then
        exit 0
    fi
    new_head="$old_head"
else
    if (( check_only )); then
        exit 0
    fi

    old_upstream_base=$(git -C "$DOTFILES_DIR" merge-base "$old_head" "$remote_head" 2>/dev/null || print -r -- "$old_head")

    has_local_commits=0
    local_commit_count=0
    if ! git -C "$DOTFILES_DIR" merge-base --is-ancestor "$old_head" "$remote_head" 2>/dev/null; then
        has_local_commits=1
        local_commit_count=$(git -C "$DOTFILES_DIR" rev-list --count "$remote_head..$old_head" 2>/dev/null || print -r -- 1)
    fi

    has_dirty_worktree=0
    if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain --untracked-files=normal 2>/dev/null)" ]]; then
        has_dirty_worktree=1
    fi

    if (( !has_local_commits && !has_dirty_worktree )); then
        print "[dotfiles] Updating dotfiles ($branch <- $remote/$remote_branch)..."
        if ! git -C "$DOTFILES_DIR" merge --ff-only --quiet "$remote_head"; then
            print -u2 "[dotfiles] Error: Fast-forward merge failed."
            exit 1
        fi
    else
        if (( has_local_commits && has_dirty_worktree )); then
            local_desc="${local_commit_count} unpublished commit(s) and uncommitted worktree changes"
        elif (( has_local_commits )); then
            local_desc="${local_commit_count} unpublished commit(s)"
        else
            local_desc="uncommitted worktree changes"
        fi

        if [[ "$local_changes_mode" == prompt ]]; then
            if [[ -t 0 ]] || zselect -t 0 -r 0 2>/dev/null; then
                printf "[dotfiles] Local changes detected (%s). [R]eapply (default), [d]iscard, or [a]bort update? [R/d/a] " "$local_desc"
                local read_ok=0 choice=""
                if [[ -t 0 ]]; then
                    if read -r -k 1 choice; then
                        read_ok=1
                        [[ "$choice" == $'\n' ]] || echo
                    fi
                else
                    if read -r choice; then
                        read_ok=1
                    fi
                fi
                if (( read_ok )); then
                    case "$choice" in
                        [rR$'\n']|$'\r'|"")
                            effective_action=reapply
                            ;;
                        [dD]*)
                            effective_action=discard
                            ;;
                        [aA]*|*)
                            effective_action=abort
                            ;;
                    esac
                else
                    echo
                    effective_action=abort
                fi
            else
                effective_action=abort
            fi
        else
            effective_action="$local_changes_mode"
        fi

        case "$effective_action" in
            abort)
                _dotfiles_write_state
                print -u2 "[dotfiles] Warning: Update aborted due to local changes ($local_desc)."
                exit 1
                ;;
            discard)
                print "[dotfiles] Discarding local changes ($local_desc) and resetting to $remote/$remote_branch..."
                git -C "$DOTFILES_DIR" reset --hard "$remote_head" --quiet
                git -C "$DOTFILES_DIR" clean -fd --quiet
                ;;
            reapply)
                print "[dotfiles] Updating dotfiles and reapplying local changes ($local_desc)..."
                stashed=0

                _dotfiles_restore_pre_update() {
                    git -C "$DOTFILES_DIR" rebase --abort >/dev/null 2>&1 || true
                    git -C "$DOTFILES_DIR" reset --hard "$old_head" --quiet >/dev/null 2>&1
                    git -C "$DOTFILES_DIR" clean -fd --quiet >/dev/null 2>&1
                    if (( stashed )); then
                        git -C "$DOTFILES_DIR" stash pop --index --quiet >/dev/null 2>&1 || \
                            git -C "$DOTFILES_DIR" stash pop --quiet >/dev/null 2>&1
                        stashed=0
                    fi
                }

                if (( has_dirty_worktree )); then
                    if ! git -C "$DOTFILES_DIR" stash push --include-untracked --quiet -m "dotfiles-auto-update-backup" >/dev/null 2>&1; then
                        _dotfiles_write_state
                        print -u2 "[dotfiles] Warning: Failed to stash uncommitted changes before update."
                        exit 1
                    fi
                    stashed=1
                fi

                if (( has_local_commits )); then
                    if ! git -C "$DOTFILES_DIR" rebase --quiet "$remote_head" >/dev/null 2>&1; then
                        _dotfiles_restore_pre_update
                        _dotfiles_write_state
                        print -u2 "[dotfiles] Warning: Failed to rebase local commits onto $remote/$remote_branch. Restored repository to its previous state."
                        exit 1
                    fi
                else
                    if ! git -C "$DOTFILES_DIR" merge --ff-only --quiet "$remote_head" >/dev/null 2>&1; then
                        _dotfiles_restore_pre_update
                        _dotfiles_write_state
                        print -u2 "[dotfiles] Warning: Failed to fast-forward to $remote/$remote_branch. Restored repository to its previous state."
                        exit 1
                    fi
                fi

                if (( stashed )); then
                    rebased_head=$(git -C "$DOTFILES_DIR" rev-parse HEAD)
                    if ! git -C "$DOTFILES_DIR" stash apply --index --quiet >/dev/null 2>&1; then
                        git -C "$DOTFILES_DIR" reset --hard "$rebased_head" --quiet >/dev/null 2>&1
                        git -C "$DOTFILES_DIR" clean -fd --quiet >/dev/null 2>&1
                        if ! git -C "$DOTFILES_DIR" stash apply --quiet >/dev/null 2>&1; then
                            _dotfiles_restore_pre_update
                            _dotfiles_write_state
                            print -u2 "[dotfiles] Warning: Failed to reapply uncommitted changes onto $remote/$remote_branch. Restored repository to its previous state."
                            exit 1
                        fi
                    fi
                    git -C "$DOTFILES_DIR" stash drop --quiet "stash@{0}" >/dev/null 2>&1
                    stashed=0
                fi
                ;;
        esac
    fi

    _dotfiles_write_state
    new_head=$(git -C "$DOTFILES_DIR" rev-parse HEAD)
    print "[dotfiles] Updated ${old_upstream_base[1,7]}..${remote_head[1,7]}:"
    git -C "$DOTFILES_DIR" log --oneline --no-decorate "$old_upstream_base..$remote_head"
fi

typeset -a changed_files adr_files
if [[ "$old_head" != "$new_head" ]]; then
    changed_files=(${(f)"$(git -C "$DOTFILES_DIR" diff --name-only "$old_head" "$new_head" 2>/dev/null)"})
    adr_files=(${(f)"$(git -C "$DOTFILES_DIR" diff --diff-filter=ADR --name-only "$old_head" "$new_head" 2>/dev/null)"})
fi

mise_bin=$(_dotfiles_find_mise 2>/dev/null || true)

need_dot_apply=0
case "$dot_apply_mode" in
    always)
        need_dot_apply=1
        ;;
    never)
        need_dot_apply=0
        ;;
    auto)
        if [[ "$old_head" != "$new_head" ]]; then
            if (( ${#adr_files} > 0 )); then
                need_dot_apply=1
            else
                for file in "${changed_files[@]}"; do
                    if [[ "$file" == (mise.toml|mise.*.toml|.miserc.toml|zsh/omz-custom/*|config/*|ssh/*|vscode/*) ]]; then
                        need_dot_apply=1
                        break
                    fi
                done
            fi
            if (( !need_dot_apply )) && [[ -n "$mise_bin" ]]; then
                diff_out=$(builtin cd -q -- "$DOTFILES_DIR" && "$mise_bin" dot diff 2>/dev/null)
                if [[ -n "$diff_out" ]]; then
                    for line in ${(f)diff_out}; do
                        if [[ "$line" != "mise files: all files are applied" && "$line" != "mise edits: all edits are applied" ]]; then
                            need_dot_apply=1
                            break
                        fi
                    done
                fi
            fi
        fi
        ;;
esac

bootstrap_files_changed=0
if [[ "$old_head" != "$new_head" ]]; then
    for file in "${changed_files[@]}"; do
        if [[ "$file" == (mise.toml|mise.*.toml|.miserc.toml|config/mise/*|tools/bootstrap/*|tools/install/*|install.sh|install.ps1) ]]; then
            bootstrap_files_changed=1
            break
        fi
    done
fi

need_bootstrap=0
case "$bootstrap_mode" in
    always)
        need_bootstrap=1
        ;;
    never)
        need_bootstrap=0
        ;;
    auto)
        need_bootstrap=$bootstrap_files_changed
        ;;
esac

if (( need_dot_apply || need_bootstrap )); then
    if [[ -z "$mise_bin" ]]; then
        print -u2 "[dotfiles] Warning: 'mise' not found; run 'mise dot apply' / 'mise bootstrap' manually in $DOTFILES_DIR."
        exit 1
    fi
    if (( need_dot_apply )); then
        print "[dotfiles] Applying dotfile links (mise dot apply)..."
        ( builtin cd -q -- "$DOTFILES_DIR" && "$mise_bin" dot apply ) || exit $?
    fi
    if (( need_bootstrap )); then
        print "[dotfiles] Bootstrap configuration changed; running 'mise bootstrap'..."
        ( builtin cd -q -- "$DOTFILES_DIR" && "$mise_bin" bootstrap ) || exit $?
    fi
fi

if [[ "$bootstrap_mode" == never ]] && (( bootstrap_files_changed )); then
    print "[dotfiles] Bootstrap files changed; run 'mise bootstrap' in $DOTFILES_DIR to apply."
fi
