#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/state.sh"
source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/content.sh"

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
GIT_TEST_FAILURE=""
TEST_DIR=""


# -----------------------------------------------------------
# GitHub CLI mock
# -----------------------------------------------------------

gh() {

    if [[ "$GH_TEST_RESULT" == "success" ]]; then

        printf '%s\n' "node_modules"

        return 0
    fi

    return 1
}


# -----------------------------------------------------------
# Git mock
#
# Normal Git operations use real Git.
# Specific operations can be forced to fail.
# -----------------------------------------------------------

git() {

    local command=""

    if [[ "${1:-}" == "-C" ]]; then
        command="${3:-}"
    else
        command="${1:-}"
    fi


    case "$command" in

        add)

            if [[ "$GIT_TEST_FAILURE" == "add" ]]; then
                return 1
            fi
            ;;


        commit)

            if [[ "$GIT_TEST_FAILURE" == "commit" ]]; then
                return 1
            fi
            ;;

    esac


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
}


create_initial_commit() {

    local repo="$1"

    printf '%s\n' "initial" > "$repo/README.md"

    "$REAL_GIT" -C "$repo" add README.md

    "$REAL_GIT" -C "$repo" commit \
        -q \
        -m "Initial commit"
}


echo
echo "Testing repository content..."
echo


# ===========================================================
# copy_readme
# ===========================================================

echo
echo "Testing copy_readme..."
echo


# -----------------------------------------------------------
# No README requested
# -----------------------------------------------------------

reset_test_state

README_FILE=""

assert_success \
    "No README requested succeeds" \
    copy_readme


# -----------------------------------------------------------
# README does not exist
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/project"
README_FILE="$TEST_DIR/missing.md"

mkdir -p "$LOCAL_PATH"

assert_failure \
    "Missing README file is rejected" \
    copy_readme

cleanup_test_environment


# -----------------------------------------------------------
# README copied successfully
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/project"
README_FILE="$TEST_DIR/source.md"

mkdir -p "$LOCAL_PATH"

printf '%s\n' "CREP README content" > "$README_FILE"

assert_success \
    "README is copied successfully" \
    copy_readme

assert_file_exists \
    "README is created in local project" \
    "$LOCAL_PATH/README.md"

assert_file_contains \
    "Copied README contains source content" \
    "$LOCAL_PATH/README.md" \
    "CREP README content"

cleanup_test_environment


# -----------------------------------------------------------
# README copy failure
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/project"
README_FILE="$TEST_DIR/source.md"

mkdir -p "$LOCAL_PATH"

printf '%s\n' "CREP README content" > "$README_FILE"

# Make destination path impossible by creating a file
# where the project directory is expected.

rm -rf "$LOCAL_PATH"

printf '%s\n' "not a directory" > "$LOCAL_PATH"

assert_failure \
    "README copy failure is detected" \
    copy_readme

cleanup_test_environment


# ===========================================================
# create_gitignore
# ===========================================================

echo
echo "Testing create_gitignore..."
echo


# -----------------------------------------------------------
# No template requested
# -----------------------------------------------------------

reset_test_state

GITIGNORE_TEMPLATE=""

assert_success \
    "No gitignore template requested succeeds" \
    create_gitignore


# -----------------------------------------------------------
# Successful gitignore creation
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/project"
GITIGNORE_TEMPLATE="Node"

mkdir -p "$LOCAL_PATH"

GH_TEST_RESULT="success"

assert_success \
    "Gitignore template is created successfully" \
    create_gitignore

assert_file_exists \
    "Gitignore file is created" \
    "$LOCAL_PATH/.gitignore"

assert_file_contains \
    "Gitignore contains template content" \
    "$LOCAL_PATH/.gitignore" \
    "node_modules"

cleanup_test_environment


# -----------------------------------------------------------
# Gitignore creation failure
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/project"
GITIGNORE_TEMPLATE="Node"

mkdir -p "$LOCAL_PATH"

GH_TEST_RESULT="failure"

assert_failure \
    "Gitignore creation failure is detected" \
    create_gitignore

cleanup_test_environment

GH_TEST_RESULT="success"


# ===========================================================
# commit_changes
# ===========================================================

echo
echo "Testing commit_changes..."
echo


# -----------------------------------------------------------
# Initial commit
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/initial"

create_test_repository "$LOCAL_PATH"

printf '%s\n' "Initial repository" > "$LOCAL_PATH/README.md"

GIT_TEST_FAILURE=""

assert_success \
    "Initial commit is created" \
    commit_changes

assert_success \
    "Initial commit exists" \
    "$REAL_GIT" \
        -C "$LOCAL_PATH" \
        rev-parse \
        --verify HEAD

cleanup_test_environment


# -----------------------------------------------------------
# Existing history + nothing to commit
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/no-changes"

create_test_repository "$LOCAL_PATH"

create_initial_commit "$LOCAL_PATH"

GIT_TEST_FAILURE=""

assert_success \
    "No changes requires no new commit" \
    commit_changes

cleanup_test_environment


# -----------------------------------------------------------
# Existing history + new changes
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/update"

create_test_repository "$LOCAL_PATH"

create_initial_commit "$LOCAL_PATH"

printf '%s\n' "Updated content" >> "$LOCAL_PATH/README.md"

GIT_TEST_FAILURE=""

assert_success \
    "Existing repository changes are committed" \
    commit_changes

assert_equals \
    "Repository contains two commits" \
    "2" \
    "$(
        "$REAL_GIT" \
            -C "$LOCAL_PATH" \
            rev-list \
            --count \
            HEAD
    )"

cleanup_test_environment


# -----------------------------------------------------------
# Staging failure
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/stage-failure"

create_test_repository "$LOCAL_PATH"

printf '%s\n' "Test" > "$LOCAL_PATH/file.txt"

GIT_TEST_FAILURE="add"

assert_failure \
    "Staging failure is detected" \
    commit_changes

cleanup_test_environment


# -----------------------------------------------------------
# Commit failure
# -----------------------------------------------------------

setup_test_environment

LOCAL_PATH="$TEST_DIR/commit-failure"

create_test_repository "$LOCAL_PATH"

printf '%s\n' "Initial" > "$LOCAL_PATH/README.md"

GIT_TEST_FAILURE="commit"

assert_failure \
    "Commit failure is detected" \
    commit_changes

cleanup_test_environment

GIT_TEST_FAILURE=""


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then

    printf 'Content tests failed: %d\n' \
        "$TEST_FAILURES"

    exit 1
fi

echo "Content tests passed."