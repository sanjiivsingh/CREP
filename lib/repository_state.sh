#!/usr/bin/env bash

# -------------------------------------------------
# Repository State Detection
# -------------------------------------------------

# shellcheck disable=SC2034,SC2153
determine_repository_state() {

    if check_local_directory "$LOCAL_PATH"; then
        LOCAL_STATUS=0
    else
        LOCAL_STATUS=$?
    fi

    if check_github_repository "$REPO_NAME"; then
        GITHUB_STATUS=0
    else
        GITHUB_STATUS=$?
    fi

    return 0
}

check_local_directory() {

    local local_path="$1"

    [[ -d "$local_path" ]]
}

check_github_repository() {

    local repo_name="$1"
    local github_user
    local response
    local http_status

    github_user="$(get_github_username)" || return 2

    response=$(gh api --include --silent \
        "repos/$github_user/$repo_name" 2>&1) || true

    http_status="$(printf '%s\n' "$response" |
        head -n 1 |
        awk '{print $2}')"

    case "$http_status" in

        200)
            return 0
            ;;

        404)
            return 1
            ;;

        *)
            return 2
            ;;

    esac
}

get_github_username() {

    gh api user --jq '.login'
}