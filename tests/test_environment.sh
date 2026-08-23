#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/environment.sh"

source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"


# -----------------------------------------------------------
# Test state
# -----------------------------------------------------------

GH_AUTH_RESULT="success"
GH_USER_RESULT="success"

TEST_DIR=""


# -----------------------------------------------------------
# GitHub CLI mock
# -----------------------------------------------------------

gh() {

    case "${1:-}" in

        auth)

            [[ "$GH_AUTH_RESULT" == "success" ]]
            ;;

        api)

            if [[ "$GH_USER_RESULT" == "success" ]]; then
                printf '%s\n' "test-user"
                return 0
            fi

            return 1
            ;;

        *)

            return 1
            ;;

    esac
}


# -----------------------------------------------------------
# Test environment
# -----------------------------------------------------------

setup_test_environment() {
    TEST_DIR="$(mktemp -d)"
}


cleanup_test_environment() {

    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi

    TEST_DIR=""
}


trap cleanup_test_environment EXIT


echo
echo "Testing environment..."
echo


# ===========================================================
# check_command
# ===========================================================

echo
echo "Testing check_command..."
echo


assert_success \
    "Existing command is detected" \
    check_command "bash"

assert_failure \
    "Missing command is rejected" \
    check_command "crep-command-that-does-not-exist"


# ===========================================================
# validate_environment
# ===========================================================

echo
echo "Testing validate_environment..."
echo


reset_test_state

assert_success \
    "Current environment is valid" \
    validate_environment

assert_not_empty \
    "Operating system is detected" \
    "$OS_NAME"

assert_not_empty \
    "Architecture is detected" \
    "$ARCHITECTURE"

assert_not_empty \
    "Shell is detected" \
    "$SHELL_NAME"

assert_contains \
    "Shell is Bash" \
    "$SHELL_NAME" \
    "Bash"


# ===========================================================
# validate_dependencies
# ===========================================================

echo
echo "Testing validate_dependencies..."
echo


# -----------------------------------------------------------
# All dependencies available
# -----------------------------------------------------------

GH_AUTH_RESULT="success"
GH_USER_RESULT="success"

reset_test_state

assert_success \
    "Dependencies pass when GitHub authentication succeeds" \
    validate_dependencies

assert_equals \
    "GitHub username is detected" \
    "test-user" \
    "$GITHUB_USER"


# -----------------------------------------------------------
# GitHub authentication failure
# -----------------------------------------------------------

GH_AUTH_RESULT="failure"

assert_failure \
    "Authentication failure is detected" \
    validate_dependencies


# -----------------------------------------------------------
# GitHub user lookup failure
# -----------------------------------------------------------

GH_AUTH_RESULT="success"
GH_USER_RESULT="failure"

assert_failure \
    "GitHub username lookup failure is detected" \
    validate_dependencies


# ===========================================================
# check_github_auth
# ===========================================================

echo
echo "Testing check_github_auth..."
echo


GH_AUTH_RESULT="success"

assert_success \
    "GitHub authentication succeeds" \
    check_github_auth


GH_AUTH_RESULT="failure"

assert_failure \
    "GitHub authentication failure is detected" \
    check_github_auth


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then

    printf 'Environment tests failed: %d\n' \
        "$TEST_FAILURES"

    exit 1
fi

echo "Environment tests passed."