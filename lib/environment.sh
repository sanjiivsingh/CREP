#!/usr/bin/env bash

# -------------------------------------------------
# Environment
# -------------------------------------------------
# shellcheck disable=SC2034
validate_environment() {

    local os_name=""
    local architecture=""
    local shell_name=""

    # -------------------------------------------------
    # Bash validation
    # -------------------------------------------------

    if [[ -z "${BASH_VERSION:-}" ]]; then
        print_error "Bash is required to run this script."
        return 1
    fi


    # -------------------------------------------------
    # Operating system detection
    # -------------------------------------------------

    case "${OSTYPE:-}" in

        darwin*)
            os_name="macOS"
            ;;

        linux*)
            os_name="Linux"
            ;;

        msys*|mingw*|cygwin*)
            os_name="Windows"
            ;;

        *)
            case "$(uname -s 2>/dev/null)" in

                Darwin)
                    os_name="macOS"
                    ;;

                Linux)
                    os_name="Linux"
                    ;;

                MINGW*|MSYS*|CYGWIN*)
                    os_name="Windows"
                    ;;

                *)
                    os_name="Unknown"
                    ;;

            esac
            ;;

    esac


    # -------------------------------------------------
    # Unsupported operating system
    # -------------------------------------------------

    if [[ "$os_name" == "Unknown" ]]; then
        print_error "Unsupported operating system."
        return 1
    fi


    # -------------------------------------------------
    # Architecture detection
    # -------------------------------------------------

    if command -v uname >/dev/null 2>&1; then

        architecture="$(uname -m 2>/dev/null || true)"

    fi

    if [[ -z "$architecture" ]]; then
        architecture="unknown"
    fi


    # -------------------------------------------------
    # Shell detection
    # -------------------------------------------------

    shell_name="Bash ${BASH_VERSION}"


    # -------------------------------------------------
    # Export detected environment
    # -------------------------------------------------

    OS_NAME="$os_name"
    ARCHITECTURE="$architecture"
    SHELL_NAME="$shell_name"


    return 0
}

check_command() {

    local command_name="$1"

    command -v "$command_name" >/dev/null 2>&1
}
# shellcheck disable=SC2034
validate_dependencies() {

    # -----------------------------------------------------------
    # Git
    # -----------------------------------------------------------

    if ! check_command "git" ; then

        print_error "Git is required."
        return 1

    fi


    # -----------------------------------------------------------
    # GitHub CLI
    # -----------------------------------------------------------

    if ! check_command "gh"; then

        print_error "GitHub CLI is required."
        return 1

    fi


    # -----------------------------------------------------------
    # GitHub authentication
    # -----------------------------------------------------------

    if ! check_github_auth; then

        print_error "GitHub authentication is required."
        print_info "Action" "Run: gh auth login"

        return 1

    fi


    # -----------------------------------------------------------
    # GitHub user
    # -----------------------------------------------------------

    GITHUB_USER="$(gh api user --jq '.login')" || {

        print_error "Unable to determine GitHub user."
        return 1

    }


    return 0
}
check_github_auth() {

    gh auth status >/dev/null 2>&1
}