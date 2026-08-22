#!/usr/bin/env bash

# ===============================================================
# Terminal Colors & Formatting
# ===============================================================

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
BOLD='\033[1m'
RESET='\033[0m'

# -------------------------------------------------
# Output Helpers
# -------------------------------------------------
print_error() {
    printf '%bError:%b %s\n' "$RED" "$RESET" "$1"
}
print_success() {
    printf '%bSuccess:%b %s\n' "$GREEN" "$RESET" "$1"
}
print_warning() {
    printf '%bWarning:%b %s\n' "$YELLOW" "$RESET" "$1"
}
print_info() {
    printf '%-25b : %b\n' "$1" "$2"
}
show_help() {

    echo

    # -----------------------------------------------------------
    # HELP
    # -----------------------------------------------------------

    printf "%b\n" "${GREEN}${BOLD} ██╗  ██╗███████╗██╗     ██████╗${RESET}"
    printf "%b\n" "${GREEN}${BOLD} ██║  ██║██╔════╝██║     ██╔══██╗${RESET}"
    printf "%b\n" "${GREEN}${BOLD} ███████║█████╗  ██║     ██████╔╝${RESET}"
    printf "%b\n" "${GREEN}${BOLD} ██╔══██║██╔══╝  ██║     ██╔═══╝${RESET}"
    printf "%b\n" "${GREEN}${BOLD} ██║  ██║███████╗███████╗██║${RESET}"
    printf "%b\n" "${GREEN}${BOLD} ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝${RESET}"

    echo

    printf "Usage:\n"
    printf "  %s <repository-name> [options]\n" "$CLI_NAME"

    echo

    printf "Options:\n"
    printf "  --local [path]              Create/use a local Git project\n"
    printf "  --public                    Create a public repository (default)\n"
    printf "  --private                   Create a private repository\n"
    printf "  --readme <file>             Use a file as README content\n"
    printf "  --gitignore <template>      Use a GitHub gitignore template\n"
    printf "  --description <text>        Set repository description\n"
    printf "  -h, --help                  Show this help message\n"

    echo

    printf "Examples:\n"
    printf "  %s my-project\n" "$CLI_NAME"
    printf "  %s my-project --local\n" "$CLI_NAME"
    printf "  %s my-project --local ./projects/my-project\n" "$CLI_NAME"
    printf "  %s my-project --private\n" "$CLI_NAME"

    echo

    printf "Requirements:\n"
    printf "  git                         Git version control\n"
    printf "  gh                          GitHub CLI\n"
    printf "  GitHub authentication       Run 'gh auth login'\n"

    echo
}
show_version() {

    printf '%s %s\n' "$CREP_NAME" "$CREP_VERSION"

}
show_banner() {

    echo

    # -----------------------------------------------------------
    # CREP
    # -----------------------------------------------------------

    printf "%b\n" "${RED}${BOLD}  ██████╗ ██████╗ ███████╗██████╗${RESET}"
    printf "%b\n" "${RED}${BOLD} ██╔════╝ ██╔══██╗██╔════╝██╔══██╗${RESET}"
    printf "%b\n" "${RED}${BOLD} ██║      ██████╔╝█████╗  ██████╔╝${RESET}"
    printf "%b\n" "${RED}${BOLD} ██║      ██╔══██╗██╔══╝  ██╔═══╝${RESET}"
    printf "%b\n" "${RED}${BOLD} ╚██████╗ ██║  ██║███████╗██║${RESET}"
    printf "%b\n" "${RED}${BOLD}  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝${RESET}"

    echo
    echo

    printf "%b\n" "${BOLD}${GREEN}  Code Repository Environment Provisioner${RESET}"
    printf "%b\n" "  GitHub + Git project lifecycle automation"
    printf '%bVersion:%b  %s  •  %bSanjeev Singh%b\n' \
        "$BLUE$BOLD" "$RESET" "$CREP_VERSION" "$RED" "$RESET"
    printf '%bGitHub:%b  %bhttps://github.com/sanjiivsingh%b\n' \
        "$BLUE" "$RESET" "$RED" "$RESET"
    echo
}
show_input_validation() {

    echo
    printf "%b\n" "${BLUE}${BOLD}Input validation:${RESET}"

    print_info "Repository name" \
        "${GREEN}valid${RESET}"

    if [[ -n "$LOCAL_PATH" ]]; then
        print_info "Local path" \
            "${GREEN}valid${RESET}"
    else
        print_info "Local path" \
            "${YELLOW}not requested${RESET}"
    fi

    if [[ -n "$README_FILE" ]]; then
        print_info "README file" \
            "${GREEN}valid${RESET}"
    else
        print_info "README file" \
            "${YELLOW}none${RESET}"
    fi

    if [[ -n "$GITIGNORE_TEMPLATE" ]]; then
        print_info "Gitignore template" \
            "${GREEN}valid${RESET}"
    else
        print_info "Gitignore template" \
            "${YELLOW}none${RESET}"
    fi
}
show_configuration() {

    echo
    printf "%b\n" "${BLUE}${BOLD}Configuration:${RESET}"

    print_info "Repository name" "$REPO_NAME"

    if [[ "$CREATE_LOCAL" == true ]]; then
        print_info "Local project" \
            "${GREEN}true${RESET}"
    else
        print_info "Local project" \
            "${YELLOW}false${RESET}"
    fi

    print_info "Local directory" \
        "${LOCAL_PATH:-${YELLOW}none${RESET}}"

    print_info "Visibility" "$VISIBILITY"

    print_info "README" \
        "${README_FILE:-${YELLOW}none${RESET}}"

    print_info "Gitignore" \
        "${GITIGNORE_TEMPLATE:-${YELLOW}none${RESET}}"

    print_info "Description" \
        "${DESCRIPTION:-${YELLOW}none${RESET}}"
}
show_environment() {

    echo
    printf "%b\n" "${BLUE}${BOLD}Environment:${RESET}"

    print_info "Operating System" "$OS_NAME"
    print_info "Architecture" "$ARCHITECTURE"
    print_info "Shell" "$SHELL_NAME"
}
show_dependencies() {

    echo
    printf "%b\n" "${BLUE}${BOLD}Dependencies:${RESET}"

    if check_command "git"; then
        print_info "git" \
            "${GREEN}installed${RESET}"
    else
        print_info "git" \
            "${RED}not installed${RESET}"
    fi

    if check_command "gh"; then
        print_info "gh" \
            "${GREEN}installed${RESET}"
    else
        print_info "gh" \
            "${RED}not installed${RESET}"
    fi

    if check_github_auth; then
        print_info "GitHub authentication" \
            "${GREEN}authenticated${RESET}"
    else
        print_info "GitHub authentication" \
            "${RED}not authenticated${RESET}"
    fi
}
show_repository_state() {

    echo
    printf "%b\n" "${BLUE}${BOLD}Repository state:${RESET}"

    if [[ "$LOCAL_STATUS" -eq 0 ]]; then
        print_info "Local directory" \
            "${GREEN}exists${RESET}"
    else
        print_info "Local directory" \
            "${RED}does not exist${RESET}"
    fi

    print_info "GitHub user" \
        "${YELLOW}${GITHUB_USER}${RESET}"

    if [[ "$GITHUB_STATUS" -eq 0 ]]; then
        print_info "GitHub repository" \
            "${GREEN}exists${RESET}"
    else
        print_info "GitHub repository" \
            "${RED}does not exist${RESET}"
    fi
}
confirm_action() {

    local message="$1"
    local answer

    printf '\n%s [y/N]: ' "$message"
    read -r answer

    case "$answer" in
        y|Y|yes|YES)
            return 0
            ;;

        *)
            print_warning "Action cancelled."
            return 1
            ;;
    esac
}