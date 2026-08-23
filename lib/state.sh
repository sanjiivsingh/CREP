#!/usr/bin/env bash

# -------------------------------------------------
# CREP State
# -------------------------------------------------

# shellcheck disable=SC2034
initialize_state() {

    # Configuration
    REPO_NAME=""
    VISIBILITY="public"
    README_FILE=""
    GITIGNORE_TEMPLATE=""
    DESCRIPTION=""
    CREATE_LOCAL=false
    LOCAL_PATH=""
    GITHUB_USER=""

    # CLI action
    CLI_ACTION="run"

    # Execution mode
    DRY_RUN=false

    # Repository state
    LOCAL_STATUS=""
    GITHUB_STATUS=""

    # Existing repository analysis
    EXISTING_GIT_STATUS=""
    EXISTING_WORKTREE_STATUS=""
    EXISTING_ORIGIN_STATUS=""
    EXISTING_HISTORY_STATUS=""
}