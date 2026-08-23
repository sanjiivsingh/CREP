#!/usr/bin/env bash

set -euo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/lib/output.sh"
source "$CREP_ROOT/lib/validation.sh"
source "$CREP_ROOT/tests/assertions.sh"


echo "Testing validate_repo_name..."
echo


assert_success \
    "Valid repository name" \
    validate_repo_name "my-project"

assert_success \
    "Repository name with numbers" \
    validate_repo_name "project123"

assert_success \
    "Repository name with underscore" \
    validate_repo_name "my_project"

assert_success \
    "Repository name with dot" \
    validate_repo_name "my.project"

assert_success \
    "Repository name with hyphen" \
    validate_repo_name "my-project"


assert_failure \
    "Empty repository name" \
    validate_repo_name ""

assert_failure \
    "Repository name containing spaces" \
    validate_repo_name "my project"

assert_failure \
    "Repository name containing slash" \
    validate_repo_name "my/project"

assert_failure \
    "Repository name containing special characters" \
    validate_repo_name "my@project"


echo
echo "Validation tests passed."