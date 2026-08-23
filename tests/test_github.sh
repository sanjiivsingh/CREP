#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/github.sh"

source "$CREP_ROOT/tests/assertions.sh"
source "$CREP_ROOT/tests/helpers.sh"


# -----------------------------------------------------------
# Real command paths
# -----------------------------------------------------------

REAL_GIT="$(command -v git)"


# -----------------------------------------------------------
# Test state
# -----------------------------------------------------------

GH_TEST_RESULT="success"
GIT_PUSH_TEST_RESULT="success"

TEST_DIR=""


# -----------------------------------------------------------
# GitHub CLI mock
# -----------------------------------------------------------

gh() {

    if [[ "$GH_TEST_RESULT" == "success" ]]; then
        return 0
    fi

    return 1
}


# -----------------------------------------------------------
# Git mock
#
# All normal Git operations are delegated to the real Git.
# Only `git push` is controlled by the test.
# -----------------------------------------------------------

git() {

    if [[ "${1:-}" == "-C" &&
          "${3:-}" == "push" ]]; then

        if [[ "$GIT_PUSH_TEST_RESULT" == "success" ]]; then
            return 0
        fi

        return 1
    fi

    "$REAL_GIT" "$@"
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


# -----------------------------------------------------------
# Create real Git repository
# -----------------------------------------------------------

create_test_repository() {

    local repo="$1"

    mkdir -p "$repo"

    "$REAL_GIT" -C "$repo" init -q

    "$REAL_GIT" -C "$repo" config \
        user.name "CREP Test"

    "$REAL_GIT" -C "$repo" config \
        user.email "crep@test.local"

    printf '%s\n' "test" > "$repo/README.md"

    "$REAL_GIT" -C "$repo" add README.md

    "$REAL_GIT" -C "$repo" commit \
        -q \
        -m "Initial commit"
}


# ===========================================================
# Start
# ===========================================================

echo
echo "Testing GitHub operations..."
echo


# ===========================================================
# build_gh_command
# ===========================================================

echo
echo "Testing build_gh_command..."
echo


# -----------------------------------------------------------
# Private repository
# -----------------------------------------------------------

reset_test_state

REPO_NAME="test-repo"
VISIBILITY="private"
DESCRIPTION="Test repository"

build_gh_command

assert_equals \
    "Private repository command is built" \
    "gh repo create test-repo --private --description Test repository" \
    "${GH_CMD[*]}"


# -----------------------------------------------------------
# Public repository
# -----------------------------------------------------------

reset_test_state

REPO_NAME="public-repo"
VISIBILITY="public"
DESCRIPTION=""

build_gh_command

assert_equals \
    "Public repository command is built" \
    "gh repo create public-repo --public" \
    "${GH_CMD[*]}"


# -----------------------------------------------------------
# Public repository with description
# -----------------------------------------------------------

reset_test_state

REPO_NAME="public-repo"
VISIBILITY="public"
DESCRIPTION="My public project"

build_gh_command

assert_equals \
    "Description is included in GitHub command" \
    "gh repo create public-repo --public --description My public project" \
    "${GH_CMD[*]}"


# ===========================================================
# create_github_repository
# ===========================================================

echo
echo "Testing create_github_repository..."
echo


GH_CMD=(
    gh
    repo
    create
    test-repo
    --private
)


# -----------------------------------------------------------
# Successful creation
# -----------------------------------------------------------

GH_TEST_RESULT="success"

assert_success \
    "GitHub repository creation succeeds" \
    create_github_repository


# -----------------------------------------------------------
# Failed creation
# -----------------------------------------------------------

GH_TEST_RESULT="failure"

assert_failure \
    "GitHub repository creation failure is detected" \
    create_github_repository


# Reset mock state

GH_TEST_RESULT="success"


# ===========================================================
# clone_github_repository
# ===========================================================

echo
echo "Testing clone_github_repository..."
echo


setup_test_environment

GITHUB_USER="test-user"
REPO_NAME="test-repo"


# -----------------------------------------------------------
# Missing local path
# -----------------------------------------------------------

LOCAL_PATH=""

assert_failure \
    "Clone fails when local path is undefined" \
    clone_github_repository


# -----------------------------------------------------------
# Existing local path
# -----------------------------------------------------------

LOCAL_PATH="$TEST_DIR/existing"

mkdir -p "$LOCAL_PATH"

assert_failure \
    "Clone fails when local path already exists" \
    clone_github_repository


# -----------------------------------------------------------
# Successful clone
# -----------------------------------------------------------

LOCAL_PATH="$TEST_DIR/new-project"

GH_TEST_RESULT="success"

assert_success \
    "Clone succeeds when GitHub clone succeeds" \
    clone_github_repository


# -----------------------------------------------------------
# Failed clone
# -----------------------------------------------------------

LOCAL_PATH="$TEST_DIR/failed-clone"

GH_TEST_RESULT="failure"

assert_failure \
    "Clone failure is detected" \
    clone_github_repository


GH_TEST_RESULT="success"

cleanup_test_environment


# ===========================================================
# push_to_github
# ===========================================================

echo
echo "Testing push_to_github..."
echo


# -----------------------------------------------------------
# Missing Git repository
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/not-git"

mkdir -p "$LOCAL_PATH"

assert_failure \
    "Push fails when Git repository does not exist" \
    push_to_github

cleanup_test_environment


# -----------------------------------------------------------
# Detached HEAD
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/detached"

create_test_repository "$LOCAL_PATH"

"$REAL_GIT" -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/test-repo.git"

"$REAL_GIT" -C "$LOCAL_PATH" checkout -q --detach HEAD

assert_failure \
    "Push fails from detached HEAD" \
    push_to_github

cleanup_test_environment


# -----------------------------------------------------------
# Missing origin
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/no-origin"

create_test_repository "$LOCAL_PATH"

assert_failure \
    "Push fails when origin is missing" \
    push_to_github

cleanup_test_environment


# -----------------------------------------------------------
# Successful push
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/push-success"

create_test_repository "$LOCAL_PATH"

"$REAL_GIT" -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/test-repo.git"

GIT_PUSH_TEST_RESULT="success"

assert_success \
    "Push succeeds when Git push succeeds" \
    push_to_github

cleanup_test_environment


# -----------------------------------------------------------
# Failed push
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/push-failure"

create_test_repository "$LOCAL_PATH"

"$REAL_GIT" -C "$LOCAL_PATH" remote add origin \
    "https://github.com/test-user/test-repo.git"

GIT_PUSH_TEST_RESULT="failure"

assert_failure \
    "Push failure is detected" \
    push_to_github


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then

    printf 'GitHub tests failed: %d\n' \
        "$TEST_FAILURES"

    exit 1
fi

echo "GitHub tests passed."