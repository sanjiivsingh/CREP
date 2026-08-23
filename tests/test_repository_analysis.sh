#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_analysis.sh"

source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"


# -----------------------------------------------------------
# Test environment
# -----------------------------------------------------------

TEST_DIR=""

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


# -----------------------------------------------------------
# Create real Git repository
# -----------------------------------------------------------

create_test_repository() {

    local repo="$1"

    mkdir -p "$repo"

    git -C "$repo" init -q

    git -C "$repo" config \
        user.name "CREP Test"

    git -C "$repo" config \
        user.email "crep@test.local"

    printf '%s\n' "test" > "$repo/README.md"

    git -C "$repo" add README.md

    git -C "$repo" commit \
        -q \
        -m "Initial commit"
}


# -----------------------------------------------------------
# Configure target GitHub origin
# -----------------------------------------------------------

configure_target_origin() {

    local repo="$1"

    git -C "$repo" remote add origin \
        "https://github.com/test-user/test-repo.git"

    GITHUB_USER="test-user"
    REPO_NAME="test-repo"
}


# -----------------------------------------------------------
# Run production function
# -----------------------------------------------------------

run_analysis() {

    inspect_existing_repository >/dev/null
}


# -----------------------------------------------------------
# Mock only remote-history operations
#
# Local Git operations remain completely real.
# -----------------------------------------------------------

mock_remote_git() {

    local local_path=""
    local git_command=""

    if [[ "${1:-}" == "-C" ]]; then

        local_path="${2:-}"
        git_command="${3:-}"

        shift 3

    else

        git_command="${1:-}"

        shift
    fi


    case "$git_command" in

        fetch)

            return 0
            ;;


        rev-parse)

            if [[ "${1:-}" == "--verify" &&
                  "${2:-}" == origin/* ]]; then

                printf '%s\n' \
                    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

                return 0
            fi

            command git \
                -C "$local_path" \
                rev-parse \
                "$@"

            return $?
            ;;


        merge-base)

            if [[ "${1:-}" == "HEAD" &&
                  "${2:-}" == origin/* ]]; then

                if [[ "${MOCK_MERGE_BASE_EXISTS:-false}" == true ]]; then

                    printf '%s\n' \
                        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

                    return 0
                fi

                return 1
            fi

            command git \
                -C "$local_path" \
                merge-base \
                "$@"

            return $?
            ;;


        rev-list)

            if [[ "${1:-}" == "--left-right" &&
                  "${2:-}" == "--count" ]]; then

                printf '%s\n' "${MOCK_COUNTS:-0 0}"

                return 0
            fi

            command git \
                -C "$local_path" \
                rev-list \
                "$@"

            return $?
            ;;


        *)

            if [[ -n "$local_path" ]]; then

                command git \
                    -C "$local_path" \
                    "$git_command" \
                    "$@"

            else

                command git \
                    "$git_command" \
                    "$@"

            fi

            return $?
            ;;

    esac
}


# ===========================================================
# Start
# ===========================================================

echo
echo "Testing inspect_existing_repository..."
echo


# ===========================================================
# 1. Directory is not a Git repository
# ===========================================================

setup_test_environment
reset_test_state

LOCAL_PATH="$TEST_DIR/not-git"

mkdir -p "$LOCAL_PATH"

run_analysis

assert_equals \
    "Non-Git directory is detected as not initialized" \
    "not_initialized" \
    "$EXISTING_GIT_STATUS"

cleanup_test_environment


# ===========================================================
# 2. Git repository has no history
# ===========================================================

setup_test_environment
reset_test_state

LOCAL_PATH="$TEST_DIR/no-history"

mkdir -p "$LOCAL_PATH"

# shellcheck disable=SC2218
git -C "$LOCAL_PATH" init -q


run_analysis

assert_equals \
    "Git repository without commits has no history" \
    "no_history" \
    "$EXISTING_GIT_STATUS"

cleanup_test_environment


# ===========================================================
# 3. Git repository with history
# ===========================================================

setup_test_environment
reset_test_state

LOCAL_PATH="$TEST_DIR/history"

create_test_repository "$LOCAL_PATH"

run_analysis

assert_equals \
    "Git repository with history exists" \
    "exists" \
    "$EXISTING_GIT_STATUS"

assert_equals \
    "Clean working tree is detected" \
    "clean" \
    "$EXISTING_WORKTREE_STATUS"

cleanup_test_environment


# ===========================================================
# 4. Dirty working tree
# ===========================================================

setup_test_environment
reset_test_state

LOCAL_PATH="$TEST_DIR/dirty"

create_test_repository "$LOCAL_PATH"

printf '%s\n' "modified" > "$LOCAL_PATH/README.md"

run_analysis

assert_equals \
    "Dirty working tree is detected" \
    "dirty" \
    "$EXISTING_WORKTREE_STATUS"

cleanup_test_environment


# ===========================================================
# 5. Origin missing
# ===========================================================

setup_test_environment
reset_test_state

LOCAL_PATH="$TEST_DIR/no-origin"

create_test_repository "$LOCAL_PATH"

run_analysis

assert_equals \
    "Missing origin is detected" \
    "missing" \
    "$EXISTING_ORIGIN_STATUS"

cleanup_test_environment


# ===========================================================
# 6. Different origin
# ===========================================================

setup_test_environment
reset_test_state

LOCAL_PATH="$TEST_DIR/different-origin"

create_test_repository "$LOCAL_PATH"
# shellcheck disable=SC2218
git -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/other-repo.git"

GITHUB_USER="test-user"
REPO_NAME="test-repo"

run_analysis

assert_equals \
    "Different origin is detected" \
    "different" \
    "$EXISTING_ORIGIN_STATUS"

cleanup_test_environment


# ===========================================================
# Prepare one real repository for history-state tests
# ===========================================================

setup_test_environment
reset_test_state

LOCAL_PATH="$TEST_DIR/history-states"

create_test_repository "$LOCAL_PATH"

configure_target_origin "$LOCAL_PATH"


# -----------------------------------------------------------
# Activate mock
# -----------------------------------------------------------

git() {
    mock_remote_git "$@"
}


# ===========================================================
# 7. Synchronized
# ===========================================================

MOCK_MERGE_BASE_EXISTS=true
MOCK_COUNTS="0 0"

run_analysis

assert_equals \
    "Synchronized history is detected" \
    "synchronized" \
    "$EXISTING_HISTORY_STATUS"


# ===========================================================
# 8. Local ahead
# ===========================================================

MOCK_MERGE_BASE_EXISTS=true
MOCK_COUNTS="2 0"

run_analysis

assert_equals \
    "Local-ahead history is detected" \
    "local_ahead" \
    "$EXISTING_HISTORY_STATUS"


# ===========================================================
# 9. Remote ahead
# ===========================================================

MOCK_MERGE_BASE_EXISTS=true
MOCK_COUNTS="0 3"

run_analysis

assert_equals \
    "Remote-ahead history is detected" \
    "remote_ahead" \
    "$EXISTING_HISTORY_STATUS"


# ===========================================================
# 10. Diverged
# ===========================================================

MOCK_MERGE_BASE_EXISTS=true
MOCK_COUNTS="2 3"

run_analysis

assert_equals \
    "Diverged history is detected" \
    "diverged" \
    "$EXISTING_HISTORY_STATUS"


# ===========================================================
# 11. Unrelated histories
# ===========================================================

MOCK_MERGE_BASE_EXISTS=false
MOCK_COUNTS="0 0"

run_analysis

assert_equals \
    "Unrelated histories are detected" \
    "unrelated" \
    "$EXISTING_HISTORY_STATUS"


# ===========================================================
# 12. Detached HEAD
# ===========================================================

git() {
    command git "$@"
}

git -C "$LOCAL_PATH" checkout -q --detach HEAD

run_analysis

assert_equals \
    "Detached HEAD produces unknown history status" \
    "unknown" \
    "$EXISTING_HISTORY_STATUS"


# ===========================================================
# Results
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then

    printf 'Repository analysis tests failed: %d\n' \
        "$TEST_FAILURES"

    exit 1
fi

echo "Repository analysis tests passed."