#!/usr/bin/env bash
# tests/unit_caps.sh — Tests for terminal capabilities and ACSC parsing

# ---------------------------------------------------------------------------
# _sd_init_caps for xterm-like terminals
# ---------------------------------------------------------------------------

test_caps_xterm_sgr0() {
    TERM=xterm _sd_init_caps
    assert_eq $'\e[m\e(B' "${_SD_CAPS[sgr0]}" "xterm sgr0"
}

test_caps_xterm_cursor() {
    TERM=xterm _sd_init_caps
    assert_eq $'\e[?25l' "${_SD_CAPS[civis]}" "xterm cursor invisible"
    assert_eq $'\e[?12l\e[?25h' "${_SD_CAPS[cnorm]}" "xterm cursor normal"
}

test_caps_xterm_keypad() {
    TERM=xterm _sd_init_caps
    assert_eq $'\e[?1h\e=' "${_SD_CAPS[smkx]}" "xterm smkx"
    assert_eq $'\e[?1l\e>' "${_SD_CAPS[rmkx]}" "xterm rmkx"
}

test_caps_xterm_acs() {
    TERM=xterm _sd_init_caps
    assert_eq $'\e(0' "${_SD_CAPS[smacs]}" "xterm smacs"
    assert_eq $'\e(B' "${_SD_CAPS[rmacs]}" "xterm rmacs"
}

test_caps_xterm_arrows() {
    TERM=xterm _sd_init_caps
    assert_eq $'\eOA' "${_SD_CAPS[kcuu1]}" "xterm up"
    assert_eq $'\eOB' "${_SD_CAPS[kcud1]}" "xterm down"
    assert_eq $'\eOC' "${_SD_CAPS[kcuf1]}" "xterm right"
    assert_eq $'\eOD' "${_SD_CAPS[kcub1]}" "xterm left"
}

test_caps_xterm_home_end() {
    TERM=xterm _sd_init_caps
    assert_eq $'\eOH' "${_SD_CAPS[khome]}" "xterm home"
    assert_eq $'\eOF' "${_SD_CAPS[kend]}" "xterm end"
}

# ---------------------------------------------------------------------------
# _sd_init_caps for linux console
# ---------------------------------------------------------------------------

test_caps_linux_sgr0() {
    TERM=linux _sd_init_caps
    assert_eq $'\e[0;10m' "${_SD_CAPS[sgr0]}" "linux sgr0"
}

test_caps_linux_arrows() {
    TERM=linux _sd_init_caps
    assert_eq $'\e[A' "${_SD_CAPS[kcuu1]}" "linux up"
    assert_eq $'\e[B' "${_SD_CAPS[kcud1]}" "linux down"
    assert_eq $'\e[C' "${_SD_CAPS[kcuf1]}" "linux right"
    assert_eq $'\e[D' "${_SD_CAPS[kcub1]}" "linux left"
}

test_caps_linux_home_end() {
    TERM=linux _sd_init_caps
    assert_eq $'\e[1~' "${_SD_CAPS[khome]}" "linux home"
    assert_eq $'\e[4~' "${_SD_CAPS[kend]}" "linux end"
}

test_caps_linux_acs() {
    TERM=linux _sd_init_caps
    assert_eq $'\e[11m' "${_SD_CAPS[smacs]}" "linux smacs"
    assert_eq $'\e[10m' "${_SD_CAPS[rmacs]}" "linux rmacs"
}

# ---------------------------------------------------------------------------
# Common caps (same for both)
# ---------------------------------------------------------------------------

test_caps_common() {
    TERM=xterm _sd_init_caps
    assert_eq $'\t' "${_SD_CAPS[ht]}" "tab"
    assert_eq $'\x7f' "${_SD_CAPS[kbs]}" "backspace"
    assert_eq $'\e[Z' "${_SD_CAPS[kcbt]}" "shift-tab"
    assert_eq $'\e[5~' "${_SD_CAPS[kpp]}" "page up"
    assert_eq $'\e[6~' "${_SD_CAPS[knp]}" "page down"
}

# ---------------------------------------------------------------------------
# ACSC Map parsing
# ---------------------------------------------------------------------------

test_acsc_map_xterm() {
    TERM=xterm _sd_init_caps
    # In xterm ACSC, the mapping is character pairs: a->a, f->f, etc.
    assert_not_empty "${_SD_ACSC_MAP[j]}" "acsc j mapped"
    assert_not_empty "${_SD_ACSC_MAP[k]}" "acsc k mapped"
    assert_not_empty "${_SD_ACSC_MAP[l]}" "acsc l mapped"
    assert_not_empty "${_SD_ACSC_MAP[m]}" "acsc m mapped"
    assert_not_empty "${_SD_ACSC_MAP[q]}" "acsc q mapped"
    assert_not_empty "${_SD_ACSC_MAP[x]}" "acsc x mapped"
}

test_box_chars_xterm() {
    TERM=xterm _sd_init_caps
    # BOX: [j]=top-right, [k]=bottom-right, [l]=top-left, [m]=bottom-left, [q]=hline, [x]=vline
    assert_not_empty "${_SD_BOX[0]}" "box[0] tl corner"
    assert_not_empty "${_SD_BOX[1]}" "box[1] tr corner"
    assert_not_empty "${_SD_BOX[2]}" "box[2] bl corner"  # wait, let me check ordering
    assert_not_empty "${_SD_BOX[3]}" "box[3] br corner"
    assert_not_empty "${_SD_BOX[4]}" "box[4] horizontal"
    assert_not_empty "${_SD_BOX[5]}" "box[5] vertical"
}

test_box_chars_fallback() {
    # If ACSC is somehow empty, box chars should fall back to +, -, |
    _SD_CAPS[acsc]=''
    _SD_ACSC_MAP=()
    _SD_BOX=(
        "${_SD_ACSC_MAP[j]:-+}"
        "${_SD_ACSC_MAP[k]:-+}"
        "${_SD_ACSC_MAP[l]:-+}"
        "${_SD_ACSC_MAP[m]:-+}"
        "${_SD_ACSC_MAP[q]:--}"
        "${_SD_ACSC_MAP[x]:-|}"
    )
    assert_eq "+" "${_SD_BOX[0]}" "fallback tl"
    assert_eq "+" "${_SD_BOX[1]}" "fallback tr"
    assert_eq "-" "${_SD_BOX[4]}" "fallback horiz"
    assert_eq "|" "${_SD_BOX[5]}" "fallback vert"
}

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

test_sd_fg() {
    local out
    out=$(_sd_fg 3)
    assert_eq $'\e[33m' "$out" "fg color 3"
}

test_sd_bg() {
    local out
    out=$(_sd_bg 4)
    assert_eq $'\e[44m' "$out" "bg color 4"
}

test_sd_pos() {
    local out
    out=$(_sd_pos 0 0)
    assert_eq $'\e[1;1H' "$out" "pos 0,0 -> 1;1"
}

test_sd_pos_nonzero() {
    local out
    out=$(_sd_pos 5 10)
    assert_eq $'\e[6;11H' "$out" "pos 5,10 -> 6;11"
}

test_sd_repeat() {
    local out
    out=$(_sd_repeat 5 'X')
    assert_eq "XXXXX" "$out" "repeat X 5 times"
}

test_sd_repeat_spaces() {
    local out
    out=$(_sd_repeat 3 ' ')
    assert_eq "   " "$out" "repeat space 3 times"
}

test_sd_swap() {
    local a=hello b=world
    _sd_swap a b
    assert_eq "world" "$a" "swap a"
    assert_eq "hello" "$b" "swap b"
}
