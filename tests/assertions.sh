#!/usr/bin/env bash

# -----------------------------------------------------------
# Test failure tracking
# -----------------------------------------------------------

TEST_FAILURES=0


# -----------------------------------------------------------
# Record test failure
# -----------------------------------------------------------

record_test_failure() {

    TEST_FAILURES=$((TEST_FAILURES + 1))
}


# -----------------------------------------------------------
# Assert command succeeds
# -----------------------------------------------------------

assert_success() {

    local description="$1"
    shift

    if "$@"; then

        printf 'PASS: %s\n' "$description"
        return 0

    fi

    printf 'FAIL: %s\n' "$description"

    record_test_failure

    return 1
}


# -----------------------------------------------------------
# Assert command fails
# -----------------------------------------------------------

assert_failure() {

    local description="$1"
    shift

    if "$@"; then

        printf 'FAIL: %s\n' "$description"

        record_test_failure

        return 1

    fi

    printf 'PASS: %s\n' "$description"

    return 0
}


# -----------------------------------------------------------
# Assert two values are equal
# -----------------------------------------------------------

assert_equals() {

    local description="$1"
    local expected="$2"
    local actual="$3"

    if [[ "$expected" == "$actual" ]]; then

        printf 'PASS: %s\n' "$description"
        return 0

    fi

    printf 'FAIL: %s\n' "$description"
    printf '  Expected: %s\n' "$expected"
    printf '  Actual:   %s\n' "$actual"

    record_test_failure

    return 1
}


# -----------------------------------------------------------
# Assert function was called
# -----------------------------------------------------------

assert_called() {

    local description="$1"
    local function_name="$2"
    local called_functions="$3"

    case " $called_functions " in

        *" $function_name "*)

            printf 'PASS: %s\n' "$description"
            return 0
            ;;

        *)

            printf 'FAIL: %s\n' "$description"
            printf '  Expected call: %s\n' "$function_name"
            printf '  Actual calls:  %s\n' \
                "${called_functions:-none}"

            record_test_failure

            return 1
            ;;

    esac
}


# -----------------------------------------------------------
# Assert function was NOT called
# -----------------------------------------------------------

assert_not_called() {

    local description="$1"
    local function_name="$2"
    local called_functions="$3"

    case " $called_functions " in

        *" $function_name "*)

            printf 'FAIL: %s\n' "$description"
            printf '  Unexpected call: %s\n' "$function_name"

            record_test_failure

            return 1
            ;;

        *)

            printf 'PASS: %s\n' "$description"
            return 0
            ;;

    esac
}

# -------------------------------------------------
# File / value assertions
# -------------------------------------------------

assert_file_exists() {

    local description="$1"
    local file="$2"

    if [[ -f "$file" ]]; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '  Expected file: %s\n' "$file"

        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
}


assert_directory_exists() {

    local description="$1"
    local directory="$2"

    if [[ -d "$directory" ]]; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '  Expected directory: %s\n' "$directory"

        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
}


assert_file_contains() {

    local description="$1"
    local file="$2"
    local expected="$3"

    if [[ ! -f "$file" ]]; then

        printf 'FAIL: %s\n' "$description"
        printf '  File does not exist: %s\n' "$file"

        TEST_FAILURES=$((TEST_FAILURES + 1))

        return
    fi

    if grep -Fq -- "$expected" "$file"; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '  Expected content: %s\n' "$expected"

        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
}


assert_not_empty() {

    local description="$1"
    local value="$2"

    if [[ -n "$value" ]]; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '  Expected a non-empty value\n'

        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
}


assert_contains() {

    local description="$1"
    local actual="$2"
    local expected="$3"

    if [[ "$actual" == *"$expected"* ]]; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '  Expected: %s\n' "$expected"
        printf '  Actual:   %s\n' "$actual"

        TEST_FAILURES=$((TEST_FAILURES + 1))
    fi
}

assert_executable() {

    local description="$1"
    local file="$2"

    if [[ -x "$file" ]]; then

        printf 'PASS: %s\n' "$description"

    else

        printf 'FAIL: %s\n' "$description"
        printf '  Expected executable: %s\n' "$file"

        exit 1
    fi
}