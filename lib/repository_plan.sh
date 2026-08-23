#!/usr/bin/env bash

# -------------------------------------------------
# Execute Repository Plan
# -------------------------------------------------
execute_repository_plan() {

    echo
    printf "%b\n" "${BLUE}${BOLD}Execution plan:${RESET}"


    # -------------------------------------------------
    # GitHub repository state could not be determined
    # -------------------------------------------------

    if [[ "$GITHUB_STATUS" -eq 2 ]]; then

        print_error "Unable to determine GitHub repository state."
        print_info "Action" "No repository changes will be performed."

        return 1
    fi


    # -------------------------------------------------
    # Dry-run mode
    # -------------------------------------------------

    if [[ "$DRY_RUN" == true ]]; then

        print_warning "DRY RUN"

        echo
        print_info "Action" "The following operations would be performed:"
        echo

        case "${LOCAL_STATUS}:${GITHUB_STATUS}" in

            # -------------------------------------------------
            # Both exist
            # -------------------------------------------------

            0:0)

                echo "Local directory and GitHub repository both exist."

                echo

                if ! inspect_existing_repository; then
                    print_error "Unable to analyze existing repository."
                    return 1
                fi

                case "$EXISTING_WORKTREE_STATUS" in

                    dirty)

                        echo "  1. No synchronization."
                        echo "     Working tree contains uncommitted changes."

                        ;;

                    *)

                        case "$EXISTING_GIT_STATUS" in

                            not_initialized)

                                echo "  1. Initialize Git repository."

                                ;;

                            no_history)

                                echo "  1. Create initial Git commit."

                                ;;

                            *)

                                case "$EXISTING_ORIGIN_STATUS" in

                                    missing)

                                        echo "  1. Configure target GitHub repository as origin."

                                        ;;

                                    different)

                                        echo "  1. No automatic remote replacement."
                                        echo "     Existing origin points to another repository."

                                        ;;

                                    target)

                                        case "$EXISTING_HISTORY_STATUS" in

                                            synchronized)

                                                echo "  1. No action required."
                                                echo "     Local and GitHub repositories are synchronized."

                                                ;;

                                            local_ahead)

                                                echo "  1. Push local commits to GitHub."

                                                ;;

                                            remote_ahead)

                                                echo "  1. Reconcile remote changes locally."
                                                echo "     No automatic push will be performed."

                                                ;;

                                            diverged)

                                                echo "  1. Manually reconcile diverged histories."
                                                echo "     No automatic synchronization will be performed."

                                                ;;

                                            unrelated)

                                                echo "  1. Manually reconcile unrelated histories."
                                                echo "     No automatic synchronization will be performed."

                                                ;;

                                            unknown)

                                                echo "  1. Manually inspect repository history."
                                                echo "     Automatic synchronization is unsafe."

                                                ;;

                                            *)

                                                echo "  1. Repository history requires manual inspection."

                                                ;;

                                        esac

                                        ;;

                                esac

                                ;;

                        esac

                        ;;

                esac

                ;;

            # -------------------------------------------------
            # Local only
            # -------------------------------------------------

            0:1)

                echo "Local directory exists, but GitHub repository does not."

                echo
                echo "Would perform:"

                echo "  1. Create GitHub repository."

                echo "  2. Prepare existing local project."

                if [[ -d "$LOCAL_PATH/.git" ]]; then

                    echo "  3. Configure existing Git repository."

                else

                    echo "  3. Initialize Git repository."
                    echo "  4. Configure GitHub repository as origin."

                fi

                echo "  5. Create/update Git commit."
                echo "  6. Push local project to GitHub."

                ;;

            # -------------------------------------------------
            # GitHub only
            # -------------------------------------------------

            1:0)

                echo "GitHub repository exists, but local directory does not."

                echo
                echo "Would perform:"
                echo "  1. Clone GitHub repository locally."

                ;;

            # -------------------------------------------------
            # Neither exists
            # -------------------------------------------------

            1:1)

                echo "Neither local directory nor GitHub repository exists."

                echo
                echo "Would perform:"
                echo "  1. Create GitHub repository."

                if [[ "$CREATE_LOCAL" == true ]]; then

                    echo "  2. Create local project directory."
                    echo "  3. Copy README."
                    echo "  4. Create .gitignore."
                    echo "  5. Initialize Git repository."
                    echo "  6. Configure GitHub repository as origin."
                    echo "  7. Create initial Git commit."
                    echo "  8. Push initial commit to GitHub."

                else

                    echo "  Local project creation is disabled."

                fi

                ;;

            # -------------------------------------------------
            # Invalid state
            # -------------------------------------------------

            *)

                print_error "Invalid repository state."

                return 1

                ;;

        esac

        echo
        print_warning "DRY RUN: No changes were made."

        return 0
    fi


    # -------------------------------------------------
    # Normal execution
    # -------------------------------------------------

    case "${LOCAL_STATUS}:${GITHUB_STATUS}" in

        0:0)
            handle_both_exist
            ;;

        0:1)
            handle_local_only
            ;;

        1:0)
            handle_github_only
            ;;

        1:1)
            handle_neither_exist
            ;;

        *)

            print_error "Invalid repository state."

            return 1

            ;;

    esac
}