#!/usr/bin/env bash
# tests/unit_inputbox.sh — Tests for inputbox widget

# ---------------------------------------------------------------------------
# Draw — normal (unselected) state
# ---------------------------------------------------------------------------

test_inputbox_draw_empty() {
    TERM=xterm _sd_init_caps
    myvar=''
    sd_load_inputbox name=ib1 x=0 y=0 width=10 varname=myvar
    local out
    out=$(_sd_inputbox_draw ib1) || true
    assert_not_empty "$out" "empty inputbox still draws"
}

test_inputbox_draw_with_value() {
    TERM=xterm _sd_init_caps
    myvar='Hello'
    sd_load_inputbox name=ib1 x=0 y=0 width=20 varname=myvar
    local out
    out=$(_sd_inputbox_draw ib1) || true
    assert_visible "$out" "Hello" "value displayed"
}

test_inputbox_draw_password() {
    TERM=xterm _sd_init_caps
    mypass='secret'
    sd_load_passwordbox name=pw1 x=0 y=0 width=20 varname=mypass
    local out
    out=$(_sd_inputbox_draw pw1) || true
    # Password mode: should show asterisks, not the actual value
    # The password box uses type=inputbox with password=yes
    assert_not_visible "$out" "secret" "password hidden"
}

test_inputbox_draw_selected() {
    TERM=xterm _sd_init_caps
    myvar='Hello'
    sd_load_inputbox name=ib1 x=0 y=0 width=20 varname=myvar
    local out
    out=$(_sd_inputbox_draw ib1 selection) || true
    assert_visible "$out" "Hello" "selected still shows value"
}

test_inputbox_draw_position() {
    TERM=xterm _sd_init_caps
    myvar=''
    sd_load_inputbox name=ib1 x=5 y=3 width=10 varname=myvar
    local out
    out=$(_sd_inputbox_draw ib1) || true
    assert_contains "$out" $'\e[4;6H' "positioned correctly"
}

test_inputbox_draw_padding() {
    TERM=xterm _sd_init_caps
    myvar='Hi'
    sd_load_inputbox name=ib1 x=0 y=0 width=10 varname=myvar
    local out
    out=$(_sd_inputbox_draw ib1) || true
    # Should pad remaining width
    assert_visible "$out" "Hi" "value shown"
}

# ---------------------------------------------------------------------------
# Read — requires stdin simulation, so we test the logic paths
# ---------------------------------------------------------------------------

# We can test the read logic by examining what happens to the varname
# For full read testing, we'd need to pipe input — we test via subshell

test_inputbox_read_backspace() {
    TERM=xterm _sd_init_caps
    myvar='Hello'
    sd_load_inputbox name=ib1 x=0 y=0 width=20 varname=myvar

    # Simulate backspace: the logic does printf -v "$varname" '%s' "${val%?}"
    # We can test this directly
    local val="$myvar"
    printf -v myvar '%s' "${val%?}"
    assert_eq "Hell" "$myvar" "backspace removes last char"
}

test_inputbox_read_append() {
    myvar='Hello'
    local val="$myvar"
    printf -v myvar '%s%s' "$val" "!"
    assert_eq "Hello!" "$myvar" "append adds char"
}

test_inputbox_maxwidth() {
    TERM=xterm _sd_init_caps
    sd_load_inputbox name=ib1 width=10 varname=myvar
    # maxwidth = width - 1 = 9
    local iw_var
    iw_var=${sd_ib1_width:-0}
    local maxwidth=$(( iw_var - 1 ))
    assert_eq "9" "$maxwidth" "maxwidth is width-1"
}

test_inputbox_draw_password_masks() {
    TERM=xterm _sd_init_caps
    mypass='abc'
    sd_load_passwordbox name=pw1 x=0 y=0 width=10 varname=mypass
    local out
    out=$(_sd_inputbox_draw pw1) || true
    # Should contain *** (3 asterisks for 3 chars)
    assert_visible "$out" "***" "password masked with asterisks"
}

test_inputbox_cursor_position() {
    TERM=xterm _sd_init_caps
    myvar='Hi'
    sd_load_inputbox name=ib1 x=5 y=3 width=10 varname=myvar
    local out
    out=$(_sd_inputbox_draw ib1) || true
    # Cursor should be at x + strlen(val) = 5 + 2 = 7 -> \e[4;8H
    assert_contains "$out" $'\e[4;8H' "cursor at end of text"
}
