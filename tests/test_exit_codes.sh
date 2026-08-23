#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/repository_state.sh"
source "$CREP_ROOT/lib/repository_analysis.sh"
source "$CREP_ROOT/lib/repository_plan.sh"
source "$CREP_ROOT/lib/repository_handlers.sh"
source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"

TEST_DIR=""

REPO_NAME="test-repo"
GITHUB_USER="test-user"
LOCAL_PATH=""

LOCAL_STATUS=0
GITHUB_STATUS=0

HANDLER_STATUS=0
OPERATION_STATUS=0

CALL_LOG=""

TEST_GITHUB_STATUS=0


# -------------------------------------------------
# Test environment
# -------------------------------------------------

setup_test_environment() {

    TEST_DIR="$(mktemp -d)"
    LOCAL_PATH="$TEST_DIR/local"

    mkdir -p "$LOCAL_PATH"
}


cleanup_test_environment() {

    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi

    TEST_DIR=""
    LOCAL_PATH=""
}


trap cleanup_test_environment EXIT


# -------------------------------------------------
# Reset state
# -------------------------------------------------

reset_exit_test_state() {

    reset_test_state

    REPO_NAME="test-repo"
    GITHUB_USER="test-user"
    LOCAL_PATH="$TEST_DIR/local"

    LOCAL_STATUS=0
    GITHUB_STATUS=0

    HANDLER_STATUS=0
    OPERATION_STATUS=0

    CALL_LOG=""

    TEST_GITHUB_STATUS=0
}


# -------------------------------------------------
# Mock helpers
# -------------------------------------------------

record_call() {

    if [[ -z "$CALL_LOG" ]]; then
        CALL_LOG="$1"
    else
        CALL_LOG="$CALL_LOG $1"
    fi
}


confirm_action() {

    record_call "confirm_action"

    return 0
}


# -------------------------------------------------
# Handler mocks
# -------------------------------------------------

handle_both_exist() {

    record_call "handle_both_exist"

    return "$HANDLER_STATUS"
}


handle_local_only() {

    record_call "handle_local_only"

    return "$HANDLER_STATUS"
}


handle_github_only() {

    record_call "handle_github_only"

    return "$HANDLER_STATUS"
}


handle_neither_exist() {

    record_call "handle_neither_exist"

    return "$HANDLER_STATUS"
}


# -------------------------------------------------
# Repository operation mocks
# -------------------------------------------------

create_github_repository() {

    record_call "create_github_repository"

    return "$OPERATION_STATUS"
}


clone_github_repository() {

    record_call "clone_github_repository"

    return "$OPERATION_STATUS"
}


push_to_github() {

    record_call "push_to_github"

    return "$OPERATION_STATUS"
}


initialize_git() {

    record_call "initialize_git"

    return "$OPERATION_STATUS"
}


configure_git_remote() {

    record_call "configure_git_remote"

    return "$OPERATION_STATUS"
}


configure_existing_git() {

    record_call "configure_existing_git"

    return "$OPERATION_STATUS"
}


commit_changes() {

    record_call "commit_changes"

    return "$OPERATION_STATUS"
}


create_local_directory() {

    record_call "create_local_directory"

    return "$OPERATION_STATUS"
}


copy_readme() {

    record_call "copy_readme"

    return "$OPERATION_STATUS"
}


create_gitignore() {

    record_call "create_gitignore"

    return "$OPERATION_STATUS"
}


prepare_existing_local() {

    record_call "prepare_existing_local"

    return "$OPERATION_STATUS"
}


build_gh_command() {

    record_call "build_gh_command"

    return 0
}


# -------------------------------------------------
# Repository state mocks
# -------------------------------------------------

check_local_directory() {

    return "$LOCAL_STATUS"
}


check_github_repository() {

    return "$TEST_GITHUB_STATUS"
}


# -------------------------------------------------
# Test header
# -------------------------------------------------

echo
echo "Testing CREP exit codes..."
echo


# =================================================
# Execution plan
# =================================================

echo
echo "Testing execute_repository_plan..."
echo


# -------------------------------------------------
# Unknown GitHub state
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=1
GITHUB_STATUS=2

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Unknown GitHub state returns failure" \
    "1" \
    "$status"

assert_equals \
    "Unknown GitHub state performs no handler action" \
    "" \
    "$CALL_LOG"

cleanup_test_environment


# -------------------------------------------------
# Invalid repository state
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=2
GITHUB_STATUS=2

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Invalid repository state returns failure" \
    "1" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# Handler failure propagates
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=0
GITHUB_STATUS=0
HANDLER_STATUS=1

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Handler failure propagates through execution plan" \
    "1" \
    "$status"

assert_equals \
    "Correct handler is selected before failure" \
    "handle_both_exist" \
    "$CALL_LOG"

cleanup_test_environment


# -------------------------------------------------
# Local-only handler failure propagates
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=0
GITHUB_STATUS=1
HANDLER_STATUS=1

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Local-only handler failure propagates" \
    "1" \
    "$status"

assert_equals \
    "Local-only handler is selected" \
    "handle_local_only" \
    "$CALL_LOG"

cleanup_test_environment


# -------------------------------------------------
# GitHub-only handler failure propagates
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=1
GITHUB_STATUS=0
HANDLER_STATUS=1

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "GitHub-only handler failure propagates" \
    "1" \
    "$status"

assert_equals \
    "GitHub-only handler is selected" \
    "handle_github_only" \
    "$CALL_LOG"

cleanup_test_environment


# -------------------------------------------------
# Neither-exist handler failure propagates
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=1
GITHUB_STATUS=1
HANDLER_STATUS=1

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Neither-exist handler failure propagates" \
    "1" \
    "$status"

assert_equals \
    "Neither-exist handler is selected" \
    "handle_neither_exist" \
    "$CALL_LOG"

cleanup_test_environment


# =================================================
# Successful execution plan
# =================================================

echo
echo "Testing successful execution paths..."
echo


# -------------------------------------------------
# Both exist succeeds
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=0
GITHUB_STATUS=0
HANDLER_STATUS=0

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Successful both-exist handler returns success" \
    "0" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# Local only succeeds
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=0
GITHUB_STATUS=1
HANDLER_STATUS=0

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Successful local-only handler returns success" \
    "0" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# GitHub only succeeds
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=1
GITHUB_STATUS=0
HANDLER_STATUS=0

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Successful GitHub-only handler returns success" \
    "0" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# Neither exists succeeds
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=1
GITHUB_STATUS=1
HANDLER_STATUS=0

execute_repository_plan >/dev/null 2>&1
status=$?

assert_equals \
    "Successful neither-exist handler returns success" \
    "0" \
    "$status"

cleanup_test_environment


# =================================================
# Individual operation failures
# =================================================

echo
echo "Testing operation failure propagation..."
echo


# -------------------------------------------------
# GitHub creation failure
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

OPERATION_STATUS=1

create_github_repository >/dev/null 2>&1
status=$?

assert_equals \
    "GitHub repository creation failure returns failure" \
    "1" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# Clone failure
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

OPERATION_STATUS=1

clone_github_repository >/dev/null 2>&1
status=$?

assert_equals \
    "GitHub clone failure returns failure" \
    "1" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# Push failure
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

OPERATION_STATUS=1

push_to_github >/dev/null 2>&1
status=$?

assert_equals \
    "Git push failure returns failure" \
    "1" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# Git initialization failure
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

OPERATION_STATUS=1

initialize_git >/dev/null 2>&1
status=$?

assert_equals \
    "Git initialization failure returns failure" \
    "1" \
    "$status"

cleanup_test_environment


# -------------------------------------------------
# Commit failure
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

OPERATION_STATUS=1

commit_changes >/dev/null 2>&1
status=$?

assert_equals \
    "Git commit failure returns failure" \
    "1" \
    "$status"

cleanup_test_environment


# =================================================
# Repository state detection
# =================================================

echo
echo "Testing repository state failure propagation..."
echo


# -------------------------------------------------
# GitHub state lookup failure
# -------------------------------------------------

setup_test_environment
reset_exit_test_state

LOCAL_STATUS=0
TEST_GITHUB_STATUS=2

determine_repository_state >/dev/null 2>&1
status=$?

assert_equals \
    "Repository state detection itself completes" \
    "0" \
    "$status"

assert_equals \
    "GitHub state lookup failure is preserved" \
    "2" \
    "$GITHUB_STATUS"

cleanup_test_environment


# =================================================
# Final result
# =================================================

echo
echo "CREP exit-code tests passed."