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
    # Repository state
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