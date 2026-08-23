#!/usr/bin/env bash

# -------------------------------------------------
# GitHub operations
# -------------------------------------------------

create_github_repository() {

    print_info "Action" "${YELLOW}Creating GitHub repository...${RESET}"

    if "${GH_CMD[@]}" >/dev/null 2>&1; then

        print_success "GitHub repository created successfully."

        record_execution_action "GitHub repository: created"

        return 0

    else

        print_error "Failed to create GitHub repository."

        EXECUTION_RESULT="failed"

        return 1

    fi
}


clone_github_repository() {

    local github_repo="$GITHUB_USER/$REPO_NAME"


    # -------------------------------------------------
    # Validate local path
    # -------------------------------------------------

    if [[ -z "$LOCAL_PATH" ]]; then

        print_error "Local path is not defined."

        EXECUTION_RESULT="failed"

        return 1

    fi


    # -------------------------------------------------
    # Prevent overwrite
    # -------------------------------------------------

    if [[ -e "$LOCAL_PATH" ]]; then

        print_error \
            "Local path already exists: $LOCAL_PATH"

        EXECUTION_RESULT="failed"

        return 1

    fi


    # -------------------------------------------------
    # Clone repository
    # -------------------------------------------------

    print_info "Action" \
        "Cloning GitHub repository..."


    if gh repo clone \
        "$github_repo" \
        "$LOCAL_PATH" \
        >/dev/null 2>&1; then

        print_info "Local directory" "cloned"
        print_info "Git repository" "cloned"
        print_info "Git history" "downloaded"
        print_info "Git remote" "origin configured"

        record_execution_action "GitHub repository: cloned"
        record_execution_action "Local directory: created"
        record_execution_action "Git repository: cloned"
        record_execution_action "Git history: downloaded"
        record_execution_action "Git remote: configured"

        return 0

    fi


    # -------------------------------------------------
    # Clone failed
    # -------------------------------------------------

    print_error "Failed to clone GitHub repository."

    EXECUTION_RESULT="failed"

    return 1
}


push_to_github() {

    local current_branch=""
    local remote_url=""


    # -------------------------------------------------
    # Validate local repository
    # -------------------------------------------------

    if [[ ! -d "$LOCAL_PATH/.git" ]]; then

        print_error "Git repository does not exist: $LOCAL_PATH"

        EXECUTION_RESULT="failed"

        return 1
    fi


    # -------------------------------------------------
    # Determine current branch
    # -------------------------------------------------

    current_branch="$(
        git -C "$LOCAL_PATH" branch --show-current 2>/dev/null
    )"

    if [[ -z "$current_branch" ]]; then

        print_error "Unable to determine current Git branch."

        EXECUTION_RESULT="failed"

        return 1
    fi


    # -------------------------------------------------
    # Verify origin exists
    # -------------------------------------------------

    remote_url="$(
        git -C "$LOCAL_PATH" remote get-url origin 2>/dev/null || true
    )"

    if [[ -z "$remote_url" ]]; then

        print_error "Git remote 'origin' is not configured."

        EXECUTION_RESULT="failed"

        return 1
    fi


    # -------------------------------------------------
    # Push current branch
    # -------------------------------------------------

    if git -C "$LOCAL_PATH" push \
        -u origin "$current_branch" \
        >/dev/null 2>&1; then

        print_info "Git push" "completed"

        record_execution_action "Git push: completed"

        return 0

    fi


    # -------------------------------------------------
    # Push failed
    # -------------------------------------------------

    print_error "Failed to push changes to GitHub."

    EXECUTION_RESULT="failed"

    return 1
}


build_gh_command() {

    GH_CMD=(gh repo create "$REPO_NAME")

    if [[ "$VISIBILITY" == "private" ]]; then
        GH_CMD+=(--private)
    else
        GH_CMD+=(--public)
    fi

    if [[ -n "$DESCRIPTION" ]]; then
        GH_CMD+=(--description "$DESCRIPTION")
    fi

}