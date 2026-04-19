#!/usr/bin/env bash
# lib.sh — Test harness for sourcedialog
#
# Provides:
#   - Terminal I/O mocking (stty, read, clear captured)
#   - Assertion helpers (assert_eq, assert_contains, assert_not_empty, etc.)
#   - Test runner with pass/fail counters
#
# Usage:
#   source tests/lib.sh
#   # ... define test functions named test_* ...
#   run_tests "$@"

_SD_TEST_LIB=1
_SD_TEST_PASSED=0
_SD_TEST_FAILED=0
_SD_TEST_TOTAL=0
_SD_TEST_CURRENT=''
_SD_TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
_SD_PROJECT_DIR="$(dirname "$_SD_TEST_DIR")"

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------

_tc_pass='\e[32m'
_tc_fail='\e[31m'
_tc_bold='\e[1m'
_tc_reset='\e[m'

# ---------------------------------------------------------------------------
# Mock infrastructure
# ---------------------------------------------------------------------------

# Output capture buffer
declare -gA _MOCK_OUTPUT=()
declare -g  _MOCK_CAPTURE=0
declare -g  _MOCK_STDOUT_FILE=''
declare -g  _MOCK_STDERR_FILE=''

# Input simulation buffer (for mocking `read`)
declare -g  _MOCK_INPUT_PIPE=''
declare -g  _MOCK_READ_FAIL=0

# stty mock tracking
declare -g  _MOCK_STTY_CALLS=''

# We mock by overriding functions the library calls.
# The library uses: stty, clear, read, printf (partially)
# We intercept via function wrappers that the library internals will call.

mock_init() {
    _MOCK_OUTPUT=()
    _MOCK_STTY_CALLS=''
    _MOCK_INPUT_PIPE=$(mktemp -u /tmp/sd_test_input.XXXXXX)
    mkfifo "$_MOCK_INPUT_PIPE" 2>/dev/null || true
    _MOCK_STDOUT_FILE=$(mktemp /tmp/sd_test_stdout.XXXXXX)
    _MOCK_STDERR_FILE=$(mktemp /tmp/sd_test_stderr.XXXXXX)
    _MOCK_READ_FAIL=0
}

mock_cleanup() {
    rm -f "$_MOCK_INPUT_PIPE" "$_MOCK_STDOUT_FILE" "$_MOCK_STDERR_FILE"
}

# Mock stty — just record calls
stty() {
    _MOCK_STTY_CALLS+="stty $*"$'\n'
}

# Mock clear — just record
clear() {
    : 
}

# We cannot easily override `read` as a function because bash builtins
# take precedence. Instead, we'll inject input via stdin pipe.
# For the tests that need to simulate `read -r -s -n1`, we redirect stdin.

# ---------------------------------------------------------------------------
# Output Capture
# ---------------------------------------------------------------------------

# Run a function and capture all stdout to a variable
# Usage: capture_output funcname [args...]
# Sets: CAPTURED_STDOUT, CAPTURED_STDERR, CAPTURED_RETVAL
capture_output() {
    local _func=$1; shift
    local _stdout _stderr _ret

    _stdout=$(mktemp /tmp/sd_test_cap.XXXXXX)
    _stderr=$(mktemp /tmp/sd_test_cap_err.XXXXXX)

    "$_func" "$@" >"$_stdout" 2>"$_stderr"; _ret=$?

    CAPTURED_STDOUT=$(<"$_stdout")
    CAPTURED_STDERR=$(<"$_stderr")
    CAPTURED_RETVAL=$_ret

    rm -f "$_stdout" "$_stderr"
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

_pass() {
    (( _SD_TEST_PASSED++ ))
    (( _SD_TEST_TOTAL++ ))
    printf "  ${_tc_pass}PASS${_tc_reset} %s\n" "$_SD_TEST_CURRENT"
}

_fail() {
    (( _SD_TEST_FAILED++ ))
    (( _SD_TEST_TOTAL++ ))
    local msg=$1
    printf "  ${_tc_fail}FAIL${_tc_reset} %s — %s\n" "$_SD_TEST_CURRENT" "$msg"
}

assert_eq() {
    local expected=$1 actual=$2 msg=${3:-}
    if [[ "$expected" == "$actual" ]]; then
        _pass
    else
        _fail "expected '$expected', got '$actual'${msg:+ — $msg}"
    fi
}

assert_not_eq() {
    local expected=$1 actual=$2 msg=${3:-}
    if [[ "$expected" != "$actual" ]]; then
        _pass
    else
        _fail "expected different from '$expected'${msg:+ — $msg}"
    fi
}

assert_contains() {
    local haystack=$1 needle=$2 msg=${3:-}
    if [[ "$haystack" == *"$needle"* ]]; then
        _pass
    else
        _fail "expected to contain '$needle'${msg:+ — $msg}"
    fi
}

assert_not_contains() {
    local haystack=$1 needle=$2 msg=${3:-}
    if [[ "$haystack" != *"$needle"* ]]; then
        _pass
    else
        _fail "expected NOT to contain '$needle'${msg:+ — $msg}"
    fi
}

assert_empty() {
    local val=$1 msg=${2:-}
    if [[ -z "$val" ]]; then
        _pass
    else
        _fail "expected empty, got '$val'${msg:+ — $msg}"
    fi
}

assert_not_empty() {
    local val=$1 msg=${2:-}
    if [[ -n "$val" ]]; then
        _pass
    else
        _fail "expected non-empty${msg:+ — $msg}"
    fi
}

assert_gt() {
    local a=$1 b=$2 msg=${3:-}
    if (( a > b )); then
        _pass
    else
        _fail "expected $a > $b${msg:+ — $msg}"
    fi
}

assert_ge() {
    local a=$1 b=$2 msg=${3:-}
    if (( a >= b )); then
        _pass
    else
        _fail "expected $a >= $b${msg:+ — $msg}"
    fi
}

assert_file_exists() {
    local f=$1 msg=${2:-}
    if [[ -f "$f" ]]; then
        _pass
    else
        _fail "expected file to exist: $f${msg:+ — $msg}"
    fi
}

# ---------------------------------------------------------------------------
# Test Runner
# ---------------------------------------------------------------------------

run_tests() {
    local _tests=()
    local _filter=${1:-}
    local _func

    # Collect all test_* functions
    while IFS= read -r _func; do
        _tests+=("$_func")
    done < <(declare -F | awk '{print $3}' | grep '^test_')

    printf "${_tc_bold}Running %d tests...${_tc_reset}\n\n" "${#_tests[@]}"

    for _func in "${_tests[@]}"; do
        # Apply filter
        [[ -n $_filter && $_func != *$_filter* ]] && continue

        _SD_TEST_CURRENT="$_func"

        # Each test gets a clean slate: re-source the library
        # (tests that need state should source it themselves)
        (
            _SD_TEST_CURRENT="$_func"
            "$_func"
        )
    done

    printf "\n${_tc_bold}Results: %d passed, %d failed, %d total${_tc_reset}\n" \
        "$_SD_TEST_PASSED" "$_SD_TEST_FAILED" "$_SD_TEST_TOTAL"

    (( _SD_TEST_FAILED > 0 )) && return 1
    return 0
}
