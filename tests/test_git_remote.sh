#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/git_remote.sh"

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


create_git_repository() {

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


echo
echo "Testing configure_existing_git..."
echo


# ===========================================================
# Missing origin
# ===========================================================

setup_test_environment

LOCAL_PATH="$TEST_DIR/missing-origin"

create_git_repository "$LOCAL_PATH"

GITHUB_USER="test-user"
REPO_NAME="test-repo"

assert_success \
    "Missing origin is configured" \
    configure_existing_git

assert_equals \
    "Missing origin points to target repository" \
    "https://github.com/test-user/test-repo.git" \
    "$(git -C "$LOCAL_PATH" remote get-url origin)"

cleanup_test_environment


# ===========================================================
# Origin already points to target
# ===========================================================

setup_test_environment

LOCAL_PATH="$TEST_DIR/target-origin"

create_git_repository "$LOCAL_PATH"

git -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/test-repo.git"

GITHUB_USER="test-user"
REPO_NAME="test-repo"

assert_success \
    "Existing target origin is accepted" \
    configure_existing_git

assert_equals \
    "Target origin remains unchanged" \
    "https://github.com/test-user/test-repo.git" \
    "$(git -C "$LOCAL_PATH" remote get-url origin)"

cleanup_test_environment


# ===========================================================
# Different origin — reject
# ===========================================================

setup_test_environment

LOCAL_PATH="$TEST_DIR/different-origin"

create_git_repository "$LOCAL_PATH"

git -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/old-repo.git"

GITHUB_USER="test-user"
REPO_NAME="test-repo"

if printf '%s\n' "n" |
    configure_existing_git >/dev/null 2>&1; then

    printf '%s\n' \
        "FAIL: Different origin is rejected"

    exit 1

else

    printf '%s\n' \
        "PASS: Different origin is rejected"

fi

assert_equals \
    "Original origin is preserved after rejection" \
    "https://github.com/test-user/old-repo.git" \
    "$(git -C "$LOCAL_PATH" remote get-url origin)"

cleanup_test_environment


# ===========================================================
# Different origin — replace
# ===========================================================

setup_test_environment

LOCAL_PATH="$TEST_DIR/replace-origin"

create_git_repository "$LOCAL_PATH"

git -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/old-repo.git"

GITHUB_USER="test-user"
REPO_NAME="test-repo"

if printf '%s\n' "y" |
    configure_existing_git >/dev/null 2>&1; then

    printf '%s\n' \
        "PASS: Different origin is replaced"

else

    printf '%s\n' \
        "FAIL: Different origin is replaced"

    exit 1

fi

assert_equals \
    "New origin points to target repository" \
    "https://github.com/test-user/test-repo.git" \
    "$(git -C "$LOCAL_PATH" remote get-url origin)"

assert_equals \
    "Old origin is preserved as old-origin" \
    "https://github.com/test-user/old-repo.git" \
    "$(git -C "$LOCAL_PATH" remote get-url old-origin)"

cleanup_test_environment


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then
    printf 'Git remote tests failed: %d\n' "$TEST_FAILURES"
    exit 1
fi

echo "Git remote tests passed."