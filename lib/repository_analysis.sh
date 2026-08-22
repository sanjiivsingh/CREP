#!/usr/bin/env bash

# -------------------------------------------------
# Existing Repository Analysis
# -------------------------------------------------

# shellcheck disable=SC2034
inspect_existing_repository() {

    # -----------------------------------------------------------
    # Reset analysis state
    # -----------------------------------------------------------

    EXISTING_GIT_STATUS=""
    EXISTING_WORKTREE_STATUS=""
    EXISTING_ORIGIN_STATUS=""
    EXISTING_HISTORY_STATUS=""

    local github_url="https://github.com/$GITHUB_USER/$REPO_NAME.git"
    local current_origin=""
    local branch=""
    local status=""
    local merge_base=""
    local remote_branch=""
    local counts=""
    local ahead=0
    local behind=0

    echo
    echo "Existing repository analysis:"

    # -----------------------------------------------------------
    # Check Git repository
    # -----------------------------------------------------------

    if [[ ! -d "$LOCAL_PATH/.git" ]]; then

        print_info "Git repository" "not initialized"

        EXISTING_GIT_STATUS="not_initialized"

        return 0
    fi

    print_info "Git repository" "exists"
    EXISTING_GIT_STATUS="exists"

    # -----------------------------------------------------------
    # Check Git history
    # -----------------------------------------------------------

    if ! git -C "$LOCAL_PATH" rev-parse --verify HEAD >/dev/null 2>&1; then

        print_info "Git history" "none"

        EXISTING_GIT_STATUS="no_history"

        return 0
    fi

    print_info "Git history" "exists"

    # -----------------------------------------------------------
    # Check current branch
    # -----------------------------------------------------------

    branch="$(
        git -C "$LOCAL_PATH" branch --show-current 2>/dev/null || true
    )"

    if [[ -n "$branch" ]]; then

        print_info "Current branch" "$branch"

    else

        print_info "Current branch" "detached HEAD"

    fi

    # -----------------------------------------------------------
    # Check working tree
    # -----------------------------------------------------------

    status="$(
        git -C "$LOCAL_PATH" status --porcelain 2>/dev/null || true
    )"

    if [[ -z "$status" ]]; then

        print_info "Working tree" "clean"

        EXISTING_WORKTREE_STATUS="clean"

    else

        print_info "Working tree" "has uncommitted changes"

        EXISTING_WORKTREE_STATUS="dirty"

    fi

    # -----------------------------------------------------------
    # Check origin
    # -----------------------------------------------------------

    current_origin="$(
        git -C "$LOCAL_PATH" remote get-url origin 2>/dev/null || true
    )"

    if [[ -z "$current_origin" ]]; then

        print_info "Origin" "not configured"

        EXISTING_ORIGIN_STATUS="missing"

        return 0
    fi

    print_info "Current origin" "$current_origin"

    # -----------------------------------------------------------
    # Compare origin with target repository
    # -----------------------------------------------------------

    if [[ "$current_origin" == "$github_url" ]]; then

        print_info "Origin" "points to target repository"

        EXISTING_ORIGIN_STATUS="target"

    else

        print_info "Origin" "points to a different repository"

        print_info "Current origin" "$current_origin"
        print_info "Target origin" "$github_url"

        EXISTING_ORIGIN_STATUS="different"

    fi

    # -----------------------------------------------------------
    # Stop if origin is not the target repository
    # -----------------------------------------------------------

    if [[ "$EXISTING_ORIGIN_STATUS" != "target" ]]; then

        return 0

    fi

    # -----------------------------------------------------------
    # Detached HEAD cannot be safely compared to a branch
    # -----------------------------------------------------------

    if [[ -z "$branch" ]]; then

        print_info "History" "unable to compare from detached HEAD"

        EXISTING_HISTORY_STATUS="unknown"

        return 0

    fi

    # -----------------------------------------------------------
    # Fetch latest remote information
    # -----------------------------------------------------------

    if ! git -C "$LOCAL_PATH" fetch origin >/dev/null 2>&1; then

        print_info "Remote history" "unable to fetch origin"

        EXISTING_HISTORY_STATUS="unknown"

        return 0

    fi

    # -----------------------------------------------------------
    # Determine remote branch
    # -----------------------------------------------------------

    remote_branch="origin/$branch"

    if ! git -C "$LOCAL_PATH" rev-parse --verify "$remote_branch" \
        >/dev/null 2>&1; then

        print_info "Remote branch" "$remote_branch not found"

        EXISTING_HISTORY_STATUS="unknown"

        return 0

    fi

    # -----------------------------------------------------------
    # Check whether histories are related
    # -----------------------------------------------------------

    merge_base="$(
        git -C "$LOCAL_PATH" merge-base HEAD "$remote_branch" \
            2>/dev/null || true
    )"

    if [[ -z "$merge_base" ]]; then

        print_info "History relationship" "unrelated histories"

        EXISTING_HISTORY_STATUS="unrelated"

        return 0

    fi

    # -----------------------------------------------------------
    # Determine ahead / behind counts
    # -----------------------------------------------------------

    counts="$(
        git -C "$LOCAL_PATH" rev-list \
            --left-right \
            --count \
            "HEAD...$remote_branch" \
            2>/dev/null || true
    )"

    if [[ -z "$counts" ]]; then

        print_info "History" "unable to determine commit counts"

        EXISTING_HISTORY_STATUS="unknown"

        return 0

    fi

    ahead="$(awk '{print $1}' <<< "$counts")"
    behind="$(awk '{print $2}' <<< "$counts")"

    # -----------------------------------------------------------
    # Validate commit counts
    # -----------------------------------------------------------

    if [[ ! "$ahead" =~ ^[0-9]+$ ]] ||
       [[ ! "$behind" =~ ^[0-9]+$ ]]; then

        print_info "History" "unable to determine commit counts"

        EXISTING_HISTORY_STATUS="unknown"

        return 0

    fi

    # -----------------------------------------------------------
    # Compare local and remote history
    # -----------------------------------------------------------

    if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then

        print_info "History" "synchronized"

        EXISTING_HISTORY_STATUS="synchronized"

    elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then

        print_info "History" \
            "local is ahead by $ahead commit(s)"

        EXISTING_HISTORY_STATUS="local_ahead"

    elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then

        print_info "History" \
            "remote is ahead by $behind commit(s)"

        EXISTING_HISTORY_STATUS="remote_ahead"

    else

        print_info "History" "branches have diverged"

        print_info "Local commits ahead" "$ahead"
        print_info "Remote commits ahead" "$behind"

        EXISTING_HISTORY_STATUS="diverged"

    fi

    return 0
}