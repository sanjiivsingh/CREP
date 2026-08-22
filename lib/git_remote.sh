#!/usr/bin/env bash

# -------------------------------------------------
# Existing Git configuration
# -------------------------------------------------

configure_existing_git() {

    local github_url="https://github.com/$GITHUB_USER/$REPO_NAME.git"
    local current_origin=""
    local answer=""


    # -------------------------------------------------
    # Check Git history
    # -------------------------------------------------

    if git -C "$LOCAL_PATH" rev-parse --verify HEAD >/dev/null 2>&1; then

        print_info "Git history" "exists"

    else

        print_info "Git history" "none"

    fi


    # -------------------------------------------------
    # Check origin
    # -------------------------------------------------

    current_origin="$(
        git -C "$LOCAL_PATH" remote get-url origin 2>/dev/null || true
    )"


    # -------------------------------------------------
    # Origin does not exist
    # -------------------------------------------------

    if [[ -z "$current_origin" ]]; then

        print_info "Git remote" "not configured"

        if git -C "$LOCAL_PATH" remote add origin "$github_url"; then

            print_info "Git remote" "origin configured"

            return 0

        fi

        print_error "Failed to configure Git remote."

        return 1

    fi


    # -------------------------------------------------
    # Origin exists
    # -------------------------------------------------

    print_info "Current origin" "$current_origin"


    # -------------------------------------------------
    # Origin already points to target
    # -------------------------------------------------

    if [[ "$current_origin" == "$github_url" ]]; then

        print_info "Git remote" \
            "already points to target repository"

        return 0

    fi


    # -------------------------------------------------
    # Origin points elsewhere
    # -------------------------------------------------

    print_info "Origin" \
        "points to a different repository."

    print_info "Current origin" "$current_origin"
    print_info "Target origin" "$github_url"


    echo

    read -r -p \
        "Replace origin with the new GitHub repository? [y/N]: " answer


    case "$answer" in

        y|Y|yes|YES)

            if git -C "$LOCAL_PATH" remote rename origin old-origin &&
               git -C "$LOCAL_PATH" remote add origin "$github_url"; then

                print_info "Git remote" "origin updated"

                print_info "Old remote" \
                    "preserved as old-origin"

                return 0

            fi

            print_error "Failed to update Git remote."

            return 1

            ;;

        *)

            print_info "Action" \
                "Existing origin was not changed."

            return 1

            ;;

    esac
}
