#!/usr/bin/env bash

# -------------------------------------------------
# Local Git Operations
# -------------------------------------------------
create_local_directory() {

    if [[ -z "$LOCAL_PATH" ]]; then
        print_error "Local path is not defined."
        return 1
    fi


    # -------------------------------------------------
    # Directory already exists
    # -------------------------------------------------

    if [[ -d "$LOCAL_PATH" ]]; then

        print_info "Local directory" "already exists"

        return 0
    fi


    # -------------------------------------------------
    # Create directory
    # -------------------------------------------------

    if mkdir -p "$LOCAL_PATH"; then

        print_info "Local directory" "created"

        return 0

    fi


    # -------------------------------------------------
    # Creation failed
    # -------------------------------------------------

    print_error "Failed to create local directory: $LOCAL_PATH"

    return 1
}
prepare_existing_local() {

    local local_path="$1"

    if [[ -z "$local_path" ]]; then
        print_error "Local path is not defined."
        return 1
    fi


    # -------------------------------------------------
    # Verify local directory
    # -------------------------------------------------

    if [[ ! -d "$local_path" ]]; then

        print_error "Local directory does not exist: $local_path"

        return 1
    fi


    return 0
}
initialize_git() {

    if [[ ! -d "$LOCAL_PATH" ]]; then
        print_error "Local directory does not exist: $LOCAL_PATH"
        return 1
    fi


    # -------------------------------------------------
    # Initialize Git repository
    # -------------------------------------------------

    if ! git -C "$LOCAL_PATH" init >/dev/null 2>&1; then

        print_error "Failed to initialize Git repository."
        return 1

    fi


    # -------------------------------------------------
    # Set default branch
    # -------------------------------------------------

    if ! git -C "$LOCAL_PATH" branch -M main >/dev/null 2>&1; then

        print_error "Failed to set default branch to main."
        return 1

    fi


    # -------------------------------------------------
    # Report result
    # -------------------------------------------------

    print_info "Git repository" "initialized"
    print_info "Default branch" "main"

    return 0
}
configure_git_remote() {

    local github_url="https://github.com/$GITHUB_USER/$REPO_NAME.git"


    # -------------------------------------------------
    # Configure origin
    # -------------------------------------------------

    if git -C "$LOCAL_PATH" remote add origin "$github_url"; then

        print_info "Git remote" "origin configured"

        return 0

    fi


    # -------------------------------------------------
    # Configuration failed
    # -------------------------------------------------

    print_error "Failed to configure Git remote."
    return 1
}