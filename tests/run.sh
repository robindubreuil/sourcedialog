#!/usr/bin/env bash
# tests/run.sh — Comprehensive test suite for sourcedialog
#
# Tests every internal function and widget in isolation, plus integration.
# Mocks stty/clear. Does NOT require a terminal.
#
# Usage:
#   bash tests/run.sh              # run all tests
#   bash tests/run.sh canvas       # run only tests matching *canvas*

set -euo pipefail

_SD_TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
_SD_PROJECT_DIR="$(dirname "$_SD_TEST_DIR")"

# ---------------------------------------------------------------------------
# Simple test framework
# ---------------------------------------------------------------------------

_PASS=0
_FAIL=0
_TOTAL=0
_CURRENT=''
declare -a _FAILURES=()

pass() { ((_PASS++)); ((_TOTAL++)); printf "  \e[32mPASS\e[m %s\n" "$_CURRENT"; }
fail() {
    local m=$1
    ((_FAIL++)); ((_TOTAL++))
    printf "  \e[31mFAIL\e[m %s — %s\n" "$_CURRENT" "$m"
    _FAILURES+=("$_CURRENT: $m")
}

assert_eq()           { local e=$1 a=$2 m=${3:-}; [[ "$e" == "$a" ]] && pass || fail "expected '$e', got '$a'${m:+ — $m}"; }
assert_not_eq()       { local e=$1 a=$2 m=${3:-}; [[ "$e" != "$a" ]] && pass || fail "expected != '$e'${m:+ — $m}"; }
assert_contains()     { local h=$1 n=$2 m=${3:-}; [[ "$h" == *"$n"* ]] && pass || fail "expected to contain '$n'${m:+ — $m}"; }
assert_not_contains() { local h=$1 n=$2 m=${3:-}; [[ "$h" != *"$n"* ]] && pass || fail "expected NOT to contain '$n'${m:+ — $m}"; }
assert_empty()        { local v=$1 m=${2:-}; [[ -z "$v" ]] && pass || fail "expected empty, got '$v'${m:+ — $m}"; }
assert_not_empty()    { local v=$1 m=${2:-}; [[ -n "$v" ]] && pass || fail "expected non-empty${m:+ — $m}"; }
assert_gt()           { local a=$1 b=$2 m=${3:-}; (( a > b )) && pass || fail "expected $a > $b${m:+ — $m}"; }
assert_ge()           { local a=$1 b=$2 m=${3:-}; (( a >= b )) && pass || fail "expected $a >= $b${m:+ — $m}"; }

strip_ansi() { printf '%s' "$1" | sed $'s/\x1b\[[0-9;]*[a-zA-Z]//g; s/\x1b[()]B//g; s/\x1b[()]0//g; s/\x1b[<>]//g; s/\x1b=//g; s/\x1b\[?[^a-zA-Z]*[a-zA-Z]//g'; }

# Assert that visible text (ANSI-stripped) contains needle
assert_visible() {
    local h=$1 n=$2 m=${3:-}
    local stripped
    stripped=$(strip_ansi "$h")
    [[ "$stripped" == *"$n"* ]] && pass || fail "expected visible text to contain '$n'${m:+ — $m}"
}
assert_not_visible() {
    local h=$1 n=$2 m=${3:-}
    local stripped
    stripped=$(strip_ansi "$h")
    [[ "$stripped" != *"$n"* ]] && pass || fail "expected visible text NOT to contain '$n'${m:+ — $m}"
}

# ---------------------------------------------------------------------------
# Re-init library state between tests
# ---------------------------------------------------------------------------

_sd_reinit() {
    # Clear any leftover widget props from previous tests FIRST
    local _pnames _pname _pval
    for _pnames in "${!_SD_PROP_LIST[@]}"; do
        for _pname in ${_SD_PROP_LIST[$_pnames]}; do
            unset "sd_${_pnames}_${_pname}" 2>/dev/null || true
        done
        # Clear extra variables not tracked in _SD_PROP_LIST
        for _pval in ilight ifirst; do
            unset "sd_${_pnames}_${_pval}" 2>/dev/null || true
        done
    done

    _SD_ORDER=()
    _SD_TYPES=()
    _SD_ACSC_MAP=()
    _SD_BOX=()
    _SD_ACTIVE=0
    _SD_PROP_LIST=()
    sd_names=()
    IFS=$' \t\n'

    _SD_BG=4; _SD_FG=7
    _SD_FRAME_BG=7; _SD_FRAME_HI=0; _SD_FRAME_LO=0
    _SD_TEXT_FG=0; _SD_TEXT_BG=7
    _SD_BTN_FG=0; _SD_BTN_BG=7; _SD_BTN_KEY=1
    _SD_BTN_SEL_FG=3; _SD_BTN_SEL_BG=4
    _SD_INPUT_FG=0; _SD_INPUT_BG=7
    _SD_INPUT_SEL_FG=7; _SD_INPUT_SEL_BG=4
    _SD_LIST_FG=4; _SD_LIST_BG=7; _SD_LIST_KEY=1
    _SD_LIST_SEL_FG=3; _SD_LIST_SEL_BG=4

    _SD_STYLE=legacy
    _SD_256COLOR=no
    _SD_SHADOW_BG=

    sd_names=()
}

# Mock terminal commands
stty() { :; }
clear() { :; }

# Source the library
source "$_SD_PROJECT_DIR/sourcedialog"

# Re-assert mocks (library may not override, but just in case)
stty() { :; }
clear() { :; }

# ---------------------------------------------------------------------------
# Source test files and collect test functions
# ---------------------------------------------------------------------------

source "$_SD_TEST_DIR/unit_load.sh"
source "$_SD_TEST_DIR/unit_caps.sh"
source "$_SD_TEST_DIR/unit_canvas.sh"
source "$_SD_TEST_DIR/unit_textbox.sh"
source "$_SD_TEST_DIR/unit_pushbutton.sh"
source "$_SD_TEST_DIR/unit_inputbox.sh"
source "$_SD_TEST_DIR/unit_listbox.sh"
source "$_SD_TEST_DIR/unit_lifecycle.sh"
source "$_SD_TEST_DIR/unit_escape.sh"
source "$_SD_TEST_DIR/unit_integration.sh"
source "$_SD_TEST_DIR/unit_regression.sh"
source "$_SD_TEST_DIR/unit_unicode.sh"

# Collect all test functions
declare -a _ALL_TESTS=()
while IFS= read -r _f; do
    _ALL_TESTS+=("$_f")
done < <(declare -F | awk '{print $3}' | grep '^test_')

_filter=${1:-}
printf "\e[1mRunning %d tests...\e[m\n\n" "${#_ALL_TESTS[@]}"

for _tfunc in "${_ALL_TESTS[@]}"; do
    [[ -n $_filter && $_tfunc != *$_filter* ]] && continue
    _CURRENT=$_tfunc
    _sd_reinit
    "$_tfunc"
done

printf "\n\e[1mResults: %d passed, %d failed, %d total\e[m\n" "$_PASS" "$_FAIL" "$_TOTAL"

if (( _FAIL > 0 )); then
    printf "\n\e[31mFailures:\e[m\n"
    for f in "${_FAILURES[@]}"; do
        printf "  - %s\n" "$f"
    done
    exit 1
fi
exit 0
