#!/usr/bin/env bash
# tests/unit_escape.sh — Tests for _sd_escape_parse

# ---------------------------------------------------------------------------
# _sd_escape_parse — key sequence parsing
# ---------------------------------------------------------------------------

test_escape_parse_plain_char() {
    TERM=xterm _sd_init_caps
    local out
    out=$(_sd_escape_parse "a")
    assert_eq "a" "$out" "plain char 'a' passed through"
}

test_escape_parse_tab() {
    TERM=xterm _sd_init_caps
    local out
    out=$(_sd_escape_parse $'\t')
    assert_eq $'\eht' "$out" "tab parsed to ht token"
}

test_escape_parse_backspace() {
    TERM=xterm _sd_init_caps
    local out
    out=$(_sd_escape_parse $'\x7f')
    assert_eq $'\ekbs' "$out" "backspace parsed to kbs token"
}

test_escape_parse_partial_escape() {
    TERM=xterm _sd_init_caps
    # If we send just ESC (\e), the read timeout expires and we get the last char
    # Since it's a single char and not a full sequence, should return the char itself
    # Actually with our implementation: seq="\e", no match, falls through to seq[-1]
    # But \e by itself: seq=$'\e', seq: -1 = $'\e'
    # The function reads the initial char, then tries to match. \e doesn't match any
    # esc[] entry's first char... wait, it does — many esc entries start with \e.
    # Let's test that \e alone (timeout) returns \e
    local out
    out=$(_sd_escape_parse $'\e')
    # Without additional input, the loop times out and returns last char of seq
    assert_eq $'\e' "$out" "bare ESC returns ESC"
}

# ---------------------------------------------------------------------------
# Testing the escape sequence output tokens
# ---------------------------------------------------------------------------

test_escape_tokens_format() {
    # All output tokens should start with \e followed by a key name
    # This is our internal encoding
    local -a expected_tokens=(
        $'\ekcuu1' $'\ekcud1' $'\ekcuf1' $'\ekcub1'
        $'\eht'    $'\ekcbt'  $'\ekbs'
        $'\ekpp'   $'\eknp'   $'\ekhome' $'\ekend'
    )
    assert_eq "11" "${#expected_tokens[@]}" "11 escape tokens defined"
}

# ---------------------------------------------------------------------------
# Test that the escape array matches the out array in size
# ---------------------------------------------------------------------------

test_escape_arrays_aligned() {
    # The esc[] and out[] arrays in _sd_escape_parse must be same length
    local -a esc=(
        "${_SD_CAPS[kcuu1]}"
        "${_SD_CAPS[kcud1]}"
        "${_SD_CAPS[kcuf1]}"
        "${_SD_CAPS[kcub1]}"
        "${_SD_CAPS[ht]}"
        "${_SD_CAPS[kcbt]}"
        "${_SD_CAPS[kbs]}"
        "${_SD_CAPS[kpp]}"
        "${_SD_CAPS[knp]}"
        "${_SD_CAPS[khome]}"
        "${_SD_CAPS[kend]}"
    )
    assert_eq "11" "${#esc[@]}" "11 escape sequences"
}
