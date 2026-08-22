#!/usr/bin/env bash

# -------------------------------------------------
# Argument Parsing
# -------------------------------------------------

# shellcheck disable=SC2034

parse_arguments() {

    while [[ $# -gt 0 ]]; do

        case "$1" in

            --local)

                CREATE_LOCAL=true

                if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                    LOCAL_PATH="$2"
                    shift 2
                else
                    LOCAL_PATH="./$REPO_NAME"
                    shift
                fi

                ;;

            --private)

                VISIBILITY="private"
                shift

                ;;

            --public)

                VISIBILITY="public"
                shift

                ;;

            --readme)

                if [[ $# -lt 2 ]]; then
                    print_error "--readme requires a file path."
                    return 1
                fi

                if [[ "$2" == -* ]]; then
                    print_error "--readme requires a file path, not an option."
                    return 1
                fi

                README_FILE="$2"
                shift 2

                ;;

            --gitignore)

                if [[ $# -lt 2 ]]; then
                    print_error "--gitignore requires a template."
                    return 1
                fi

                if [[ "$2" == -* ]]; then
                    print_error "--gitignore requires a template."
                    return 1
                fi

                GITIGNORE_TEMPLATE="$2"
                shift 2

                ;;

            --description)

                if [[ $# -lt 2 ]]; then
                    print_error "--description requires text."
                    return 1
                fi

                DESCRIPTION="$2"
                shift 2

                ;;

            -h|--help)

                CLI_ACTION="help"
                return 0

                ;;

            --version)
                CLI_ACTION="version"
                return 0

                ;;

            -*)

                print_error "unknown option: $1"
                return 1

                ;;

            *)

                if [[ -z "$REPO_NAME" ]]; then

                    REPO_NAME="$1"
                    shift

                else

                    print_error "unexpected argument: $1"
                    return 1

                fi

                ;;

        esac

    done

    return 0
}