#!/usr/bin/env bash

# -------------------------------------------------
# Repository content
# -------------------------------------------------

copy_readme() {

    # -------------------------------------------------
    # No README requested
    # -------------------------------------------------

    if [[ -z "$README_FILE" ]]; then
        return 0
    fi


    # -------------------------------------------------
    # Validate source README
    # -------------------------------------------------

    if [[ ! -f "$README_FILE" ]]; then

        print_error "README file not found: $README_FILE"

        EXECUTION_RESULT="failed"

        return 1
    fi


    # -------------------------------------------------
    # Copy README into local project
    # -------------------------------------------------

    if cp "$README_FILE" "$LOCAL_PATH/README.md"; then

        print_info "README file" "copied"

        record_execution_action "README: copied"

        return 0
    fi


    # -------------------------------------------------
    # Copy failed
    # -------------------------------------------------

    print_error "Failed to copy README file."

    EXECUTION_RESULT="failed"

    return 1
}


create_gitignore() {

    # -------------------------------------------------
    # No gitignore template requested
    # -------------------------------------------------

    if [[ -z "$GITIGNORE_TEMPLATE" ]]; then
        return 0
    fi


    # -------------------------------------------------
    # Create .gitignore
    # -------------------------------------------------

    if gh repo gitignore view "$GITIGNORE_TEMPLATE" \
        > "$LOCAL_PATH/.gitignore" 2>/dev/null; then

        print_info "Gitignore template" "created"

        record_execution_action "Gitignore: created"

        return 0
    fi


    # -------------------------------------------------
    # Creation failed
    # -------------------------------------------------

    print_error "Failed to create .gitignore."

    EXECUTION_RESULT="failed"

    return 1
}


commit_changes() {

    # -------------------------------------------------
    # Stage changes
    # -------------------------------------------------

    if git -C "$LOCAL_PATH" add . >/dev/null 2>&1; then

        print_info "Git staging" "completed"

    else

        print_error "Failed to stage Git changes."

        EXECUTION_RESULT="failed"

        return 1

    fi


    # -------------------------------------------------
    # Case 1: No commit exists yet
    # -------------------------------------------------

    if ! git -C "$LOCAL_PATH" rev-parse --verify HEAD >/dev/null 2>&1; then

        if git -C "$LOCAL_PATH" commit \
            --allow-empty \
            -m "Initial commit" \
            >/dev/null 2>&1; then

            print_info "Git commit" "created initial commit"

            record_execution_action "Git commit: initial commit created"

            return 0

        fi

        print_error "Failed to create initial Git commit."

        EXECUTION_RESULT="failed"

        return 1
    fi


    # -------------------------------------------------
    # Case 2: Existing history + no staged changes
    # -------------------------------------------------

    if git -C "$LOCAL_PATH" diff --cached --quiet >/dev/null 2>&1; then

        print_info "Git commit" "nothing to commit"

        return 0
    fi


    # -------------------------------------------------
    # Case 3: Existing history + new changes
    # -------------------------------------------------

    if git -C "$LOCAL_PATH" commit \
        -m "Update repository" \
        >/dev/null 2>&1; then

        print_info "Git commit" "created"

        record_execution_action "Git commit: update created"

        return 0

    fi


    # -------------------------------------------------
    # Commit failed
    # -------------------------------------------------

    print_error "Failed to create Git commit."

    EXECUTION_RESULT="failed"

    return 1
}