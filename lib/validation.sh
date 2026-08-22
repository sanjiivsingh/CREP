#!/usr/bin/env bash

validate_inputs() {

    if [[ -z "$REPO_NAME" ]]; then
        print_error "Repository name is required."
        return 1
    fi

    validate_repo_name "$REPO_NAME" || return 1

    normalize_local_path || return 1

    validate_local_path || return 1

    if [[ -n "$README_FILE" ]]; then
        validate_readme "$README_FILE" || return 1
    fi

    if [[ -n "$GITIGNORE_TEMPLATE" ]]; then
        validate_gitignore "$GITIGNORE_TEMPLATE" || return 1
    fi

    return 0
}
validate_repo_name() {
    local repo_name="$1"

    if [[ -z "$repo_name" ]]; then
        print_error "Repository name cannot be empty"
        return 1
    fi
    if [[ ! "$repo_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        print_error "Invalid repository name: $repo_name"
        echo "Allowed characters: letters, numbers . _ -"
        return 1
    fi

    return 0
}
normalize_local_path() {

    if [[ -z "$LOCAL_PATH" ]]; then
        return 0
    fi


    # -------------------------------------------------
    # Already an absolute path
    # -------------------------------------------------

    if [[ "$LOCAL_PATH" == /* ]]; then
        return 0
    fi


    # -------------------------------------------------
    # Resolve relative path
    # -------------------------------------------------

    local current_directory

    current_directory="$(pwd)" || {
        print_error "Unable to determine current directory."
        return 1
    }


    # Remove leading "./" if present
    LOCAL_PATH="${LOCAL_PATH#./}"

    LOCAL_PATH="$current_directory/$LOCAL_PATH"

    return 0
}
validate_readme() {
    local readme_file="$1"

    if [[ ! -f "$readme_file" ]]; then
        print_error "README file not found: $readme_file"
        return 1
    fi

    print_info "README file" "${GREEN}valid${RESET}"
    return 0
}
validate_gitignore() {
    local template="$1"

    if gh repo gitignore view "$template" >/dev/null 2>&1; then
        print_info "Gitignore template" "${GREEN}valid${RESET}"
        return 0
    fi

    print_error "Gitignore template not found: $template"
    return 1
}
validate_local_path() {

    if [[ -z "$LOCAL_PATH" ]]; then
        return 0
    fi

    # -------------------------------------------------
    # Path already exists
    # -------------------------------------------------

    if [[ -e "$LOCAL_PATH" ]]; then

        if [[ ! -d "$LOCAL_PATH" ]]; then
            print_error \
                "Local path exists but is not a directory: $LOCAL_PATH"
            return 1
        fi

        return 0
    fi


    # -------------------------------------------------
    # Path does not exist yet
    # -------------------------------------------------
    #
    # This is valid because CREP may create it later.
    #

    return 0
}