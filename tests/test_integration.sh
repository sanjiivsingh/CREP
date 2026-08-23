#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CREP="$CREP_ROOT/bin/crep"

source "$CREP_ROOT/tests/assertions.sh"


echo
echo "Testing CREP CLI integration..."
echo


# -----------------------------------------------------------
# Helper
# -----------------------------------------------------------

assert_command_success() {

    local description="$1"
    shift

    local output

    if output="$("$@" 2>&1)"; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '%s\n' "$output"

        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
}


assert_command_failure() {

    local description="$1"
    shift

    local output

    if output="$("$@" 2>&1)"; then

        printf 'FAIL: %s\n' "$description"
        printf "Expected command to fail\n"

        TEST_FAILURES=$((TEST_FAILURES + 1))

    else

        printf 'PASS: %s\n' "$description"

    fi
}


assert_command_output_contains() {

    local description="$1"
    local expected="$2"
    shift 2

    local output

    output="$("$@" 2>&1)" || true

    if [[ "$output" == *"$expected"* ]]; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '  Expected output: %s\n' "$expected"
        printf '  Actual output:\n%s\n' "$output"

        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
}


# ===========================================================
# Help
# ===========================================================

echo
echo "Testing help..."
echo


assert_command_success \
    "Help action succeeds" \
    "$CREP" \
    --help


assert_command_output_contains \
    "Help usage is displayed" \
    "Usage:" \
    "$CREP" \
    --help


# ===========================================================
# Version
# ===========================================================

echo
echo "Testing version..."
echo


assert_command_success \
    "Version action succeeds" \
    "$CREP" \
    --version


assert_command_output_contains \
    "Version output contains version" \
    "CREP" \
    "$CREP" \
    --version


# ===========================================================
# Argument validation
# ===========================================================

echo
echo "Testing CLI argument validation..."
echo


assert_command_failure \
    "Unknown option is rejected" \
    "$CREP" \
    --unknown


assert_command_failure \
    "Empty repository name is rejected" \
    "$CREP" \
    ""


assert_command_failure \
    "README option without value is rejected" \
    "$CREP" \
    test-repo \
    --readme


assert_command_failure \
    "Gitignore option without value is rejected" \
    "$CREP" \
    test-repo \
    --gitignore


assert_command_failure \
    "Description option without value is rejected" \
    "$CREP" \
    test-repo \
    --description


assert_command_failure \
    "Unexpected second repository argument is rejected" \
    "$CREP" \
    test-repo \
    another-repo


# ===========================================================
# Invalid repository name
# ===========================================================

echo
echo "Testing repository-name validation..."
echo


assert_command_failure \
    "Repository name containing spaces is rejected" \
    "$CREP" \
    "my project"


assert_command_failure \
    "Repository name containing slash is rejected" \
    "$CREP" \
    "my/project"


assert_command_failure \
    "Repository name containing special characters is rejected" \
    "$CREP" \
    "my@project"


# ===========================================================
# Dependency failure
# ===========================================================

echo
echo "Testing dependency failure..."
echo


TEMP_DIR="$(mktemp -d)"

cleanup() {

    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT


# Fake gh that fails authentication.

cat > "$TEMP_DIR/gh" <<'EOF'
#!/usr/bin/env bash

exit 1
EOF

chmod +x "$TEMP_DIR/gh"


# Keep real system commands available while forcing
# the fake GitHub CLI to be selected first.

PATH="$TEMP_DIR:$PATH"

export PATH


assert_command_failure \
    "CLI fails when GitHub authentication is unavailable" \
    "$CREP" \
    test-repo


# ===========================================================
# Result
# ===========================================================

echo

if [[ "$TEST_FAILURES" -gt 0 ]]; then

    printf 'Integration tests failed: %d\n' \
        "$TEST_FAILURES"

    exit 1
fi

echo "Integration tests passed."