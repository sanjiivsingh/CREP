#!/usr/bin/env bash

set -uo pipefail

CREP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CREP_ROOT/tests/assertions.sh"

echo
echo "CREP Test Suite"
echo "=============================="
echo

failed=0
test_count=0

for test_file in "$CREP_ROOT"/tests/test_*.sh; do

    [[ "$test_file" == "$CREP_ROOT/tests/test_runner.sh" ]] && continue

    test_count=$((test_count + 1))

    echo "Running: $(basename "$test_file")"
    echo

    if "$test_file"; then
        echo
        echo "PASS: $(basename "$test_file")"
    else
        echo
        echo "FAIL: $(basename "$test_file")"
        failed=$((failed + 1))
    fi

    echo
done

echo "=============================="
echo "Tests:  $test_count"
echo "Failed: $failed"
echo

if [[ "$failed" -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi

echo "TESTS FAILED"
exit 1