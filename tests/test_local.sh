#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/local.sh"

source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"


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


echo
echo "Testing local Git operations..."
echo


# ===========================================================
# create_local_directory
# ===========================================================

echo
echo "Testing create_local_directory..."
echo


LOCAL_PATH=""

assert_failure \
    "Local directory creation fails without path" \
    create_local_directory


setup_test_environment

LOCAL_PATH="$TEST_DIR/project"

assert_success \
    "Local directory is created" \
    create_local_directory

assert_directory_exists \
    "Created local directory exists" \
    "$LOCAL_PATH"

assert_success \
    "Existing local directory is accepted" \
    create_local_directory

cleanup_test_environment


# ===========================================================
# prepare_existing_local
# ===========================================================

echo
echo "Testing prepare_existing_local..."
echo


assert_failure \
    "Existing local preparation fails without path" \
    prepare_existing_local ""


setup_test_environment

LOCAL_PATH="$TEST_DIR/missing"

assert_failure \
    "Missing local directory is rejected" \
    prepare_existing_local "$LOCAL_PATH"

mkdir -p "$LOCAL_PATH"

assert_success \
    "Existing local directory is prepared" \
    prepare_existing_local "$LOCAL_PATH"

cleanup_test_environment


# ===========================================================
# initialize_git
# ===========================================================

echo
echo "Testing initialize_git..."
echo


setup_test_environment

LOCAL_PATH="$TEST_DIR/missing"

assert_failure \
    "Git initialization fails when directory is missing" \
    initialize_git

cleanup_test_environment


setup_test_environment

LOCAL_PATH="$TEST_DIR/project"

mkdir -p "$LOCAL_PATH"

assert_success \
    "Git repository is initialized" \
    initialize_git

assert_directory_exists \
    "Git directory exists after initialization" \
    "$LOCAL_PATH/.git"

assert_equals \
    "Default branch is main" \
    "main" \
    "$(git -C "$LOCAL_PATH" branch --show-current)"

cleanup_test_environment


# ===========================================================
# configure_git_remote
# ===========================================================

echo
echo "Testing configure_git_remote..."
echo


setup_test_environment

LOCAL_PATH="$TEST_DIR/project"

mkdir -p "$LOCAL_PATH"

git -C "$LOCAL_PATH" init -q

GITHUB_USER="test-user"
REPO_NAME="test-repo"

assert_success \
    "GitHub origin is configured" \
    configure_git_remote

assert_equals \
    "GitHub origin points to target repository" \
    "https://github.com/test-user/test-repo.git" \
    "$(git -C "$LOCAL_PATH" remote get-url origin)"

cleanup_test_environment


# -----------------------------------------------------------
# Existing origin causes configuration failure
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/project"

mkdir -p "$LOCAL_PATH"

git -C "$LOCAL_PATH" init -q

git -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/other-repo.git"

GITHUB_USER="test-user"
REPO_NAME="test-repo"

assert_failure \
    "Git remote configuration rejects existing origin" \
    configure_git_remote

cleanup_test_environment


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then
    printf 'Local tests failed: %d\n' "$TEST_FAILURES"
    exit 1
fi

echo "Local tests passed."