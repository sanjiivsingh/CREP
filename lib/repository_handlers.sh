#!/usr/bin/env bash

# -------------------------------------------------
# Repository Handlers
# -------------------------------------------------
handle_both_exist() {

    echo "Local directory and GitHub repository both exist."

    inspect_existing_repository || return 1


    # -------------------------------------------------
    # Working tree
    # -------------------------------------------------

    if [[ "$EXISTING_WORKTREE_STATUS" == "dirty" ]]; then

        print_info "Action" \
            "Working tree has uncommitted changes."

        print_info "Action" \
            "No automatic synchronization will be performed."

        return 0

    fi


    # -------------------------------------------------
    # Git repository state
    # -------------------------------------------------

    case "$EXISTING_GIT_STATUS" in

        not_initialized)

            print_info "Local project" \
                "directory exists but is not a Git repository."

            print_info "Action" \
                "Git initialization is required before synchronization."

            ;;

        no_history)

            print_info "Git history" \
                "local repository has no commits."

            print_info "Action" \
                "A commit is required before synchronization."

            ;;

        *)

            # -----------------------------------------
            # Git remote state
            # -----------------------------------------

            case "$EXISTING_ORIGIN_STATUS" in

                missing)

                    print_info "Origin" \
                        "local repository has no origin."

                    print_info "Action" \
                        "Target GitHub repository can be configured as origin."

                    ;;

                different)

                    print_info "Origin" \
                        "points to a different GitHub repository."

                    print_info "Action" \
                        "Existing origin must be explicitly replaced."

                    ;;

                target)

                    # ---------------------------------
                    # Repository history
                    # ---------------------------------

                    case "$EXISTING_HISTORY_STATUS" in

                        synchronized)

                            print_success \
                                "Local and GitHub repositories are synchronized."

                            print_info "Action" \
                                "No synchronization required."

                            ;;

                        local_ahead)

                            print_info "Action" \
                                "Local commits can be pushed to GitHub."

                            echo

                            if confirm_action \
                                "Push local commits to GitHub?"; then

                                push_to_github || return 1

                            else

                                print_info "Action" \
                                    "No changes made."

                            fi

                            ;;

                        remote_ahead)

                            print_info "History" \
                                "GitHub contains commits not present locally."

                            print_info "Action" \
                                "Pull/reconciliation is required before pushing."

                            ;;

                        diverged)

                            print_info "History" \
                                "Local and GitHub histories have diverged."

                            print_info "Action" \
                                "Manual reconciliation is required."

                            ;;

                        unrelated)

                            print_info "History" \
                                "Local and GitHub histories are unrelated."

                            print_info "Action" \
                                "Manual reconciliation is required."

                            ;;

                        unknown)

                            print_info "History" \
                                "Unable to safely compare histories."

                            print_info "Action" \
                                "Manual inspection is required."

                            ;;

                    esac
                    ;;

            esac
            ;;

    esac

    return 0
}
handle_local_only() {

    # -------------------------------------------------
    # Local exists + GitHub does not exist
    # -------------------------------------------------

    echo "Local directory exists, but GitHub repository does not."

    print_info "Action" \
        "The existing local project can be used."


    # -------------------------------------------------
    # Build GitHub repository command
    # -------------------------------------------------

    build_gh_command


    # -------------------------------------------------
    # Confirm repository creation
    # -------------------------------------------------

    if ! confirm_action "Continue with repository creation?"; then

        print_info "Action" "No changes made."

        return 0

    fi


    # -------------------------------------------------
    # Create GitHub repository
    # -------------------------------------------------

    create_github_repository || return 1


    # -------------------------------------------------
    # Prepare existing local project
    # -------------------------------------------------

    prepare_existing_local "$LOCAL_PATH" || return 1


    # -------------------------------------------------
    # Configure Git repository
    # -------------------------------------------------

    if git -C "$LOCAL_PATH" rev-parse --git-dir >/dev/null 2>&1; then

        configure_existing_git || return 1

    else

        initialize_git || return 1
        configure_git_remote || return 1

    fi


    # -------------------------------------------------
    # Commit and push
    # -------------------------------------------------

    commit_changes || return 1
    push_to_github || return 1


    return 0
}
handle_github_only() {

    # -------------------------------------------------
    # GitHub exists + Local does not exist
    # -------------------------------------------------

    echo "GitHub repository exists, but local directory does not."


    # -------------------------------------------------
    # Confirm clone
    # -------------------------------------------------

    if confirm_action "Clone the GitHub repository locally?"; then

        clone_github_repository || return 1

    else

        print_info "Action" "No changes made."

        return 0

    fi


    return 0
}
handle_neither_exist() {

    # -------------------------------------------------
    # Neither local directory nor GitHub repository
    # exists
    # -------------------------------------------------

    echo "Neither local directory nor GitHub repository exists."

    print_success "Ready to create a new repository."


    # -------------------------------------------------
    # Build GitHub repository command
    # -------------------------------------------------

    build_gh_command


    # -------------------------------------------------
    # Confirm repository creation
    # -------------------------------------------------

    if ! confirm_action "Continue with repository creation?"; then

        print_info "Action" "No changes made."

        return 0

    fi


    # -------------------------------------------------
    # Create GitHub repository
    # -------------------------------------------------

    create_github_repository || return 1


    # -------------------------------------------------
    # Create and configure local project
    # -------------------------------------------------

    if [[ "$CREATE_LOCAL" == true ]]; then

        create_local_directory || return 1

        copy_readme || return 1

        create_gitignore || return 1

        initialize_git || return 1

        configure_git_remote || return 1

        commit_changes || return 1

        push_to_github || return 1

    fi


    return 0
}