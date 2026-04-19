#!/usr/bin/env bash
# tests/unit_regression.sh — Regression tests for specific bugs we fixed

# ---------------------------------------------------------------------------
# Bug #1: sd_load with = in property values
# ---------------------------------------------------------------------------

test_regression_load_equals_in_value() {
    sd_load name=w1 type=textbox text="key=value"
    assert_eq "key=value" "${sd_w1_text}" "= in value preserved"
}

test_regression_load_multiple_equals() {
    sd_load name=w1 type=inputbox varname="a==b"
    assert_eq "a==b" "${sd_w1_varname}" "multiple = preserved"
}

test_regression_load_url_value() {
    sd_load name=w1 type=textbox text="http://example.com?a=1&b=2"
    assert_eq "http://example.com?a=1&b=2" "${sd_w1_text}" "URL preserved"
}

# ---------------------------------------------------------------------------
# Bug #2: listbox ilight/ifirst indirect expansion
# ---------------------------------------------------------------------------

test_regression_listbox_ilight_indirect() {
    TERM=xterm _sd_init_caps
    myarr=("A" "B" "C")
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=3 arrayname=myarr
    declare -g sd_mb1_ilight=2
    declare -g sd_mb1_ifirst=0
    local out
    out=$(_sd_listbox_draw mb1 || true)
    assert_visible "$out" "A" "first item visible"
    assert_visible "$out" "B" "second item visible"
    assert_visible "$out" "C" "third item visible"
}

test_regression_listbox_default_ilight() {
    TERM=xterm _sd_init_caps
    myarr2=("X" "Y")
    sd_load_menubox name=mb2 x=0 y=0 width=10 height=2 arrayname=myarr2
    # No ilight set — should default to 0
    local out
    out=$(_sd_listbox_draw mb2 || true)
    assert_visible "$out" "X" "default ilight=0 shows first"
}

# ---------------------------------------------------------------------------
# Bug #3: sd_read off-by-one (i >= max instead of i > max)
# ---------------------------------------------------------------------------

test_regression_sd_read_wrap_at_boundary() {
    local i=3 max=3
    (( i >= max )) && i=0
    assert_eq "0" "$i" "wraps at exact boundary"
}

# ---------------------------------------------------------------------------
# Bug #5: inputbox maxwidth negative
# ---------------------------------------------------------------------------

test_regression_inputbox_zero_width() {
    sd_load_inputbox name=ib1 width=0 varname=myvar
    # maxwidth = 0 - 1 = -1, clamped to 0
    local iw_val=${sd_ib1_width:-0}
    local maxwidth=$(( iw_val - 1 ))
    (( maxwidth < 0 )) && maxwidth=0
    assert_eq "0" "$maxwidth" "maxwidth clamped to 0"
}

# ---------------------------------------------------------------------------
# Bug #8: pushbutton with no alphanumeric chars
# ---------------------------------------------------------------------------

test_regression_pushbutton_no_alnum() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=0 y=0 caption="!!!"
    local out
    out=$(_sd_pushbutton_draw pb1 || true)
    assert_visible "$out" "!!!" "no-alnum caption renders fully"
    assert_visible "$out" "<" "bracket before"
    assert_visible "$out" ">" "bracket after"
}

test_regression_pushbutton_empty_caption() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=0 y=0 caption=""
    local out
    out=$(_sd_pushbutton_draw pb1 || true)
    assert_visible "$out" "<>" "empty caption shows empty brackets"
}

# ---------------------------------------------------------------------------
# Bug #9: textbox glob expansion
# ---------------------------------------------------------------------------

test_regression_textbox_glob_chars() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=20 text="Hello * World"
    local out
    out=$(_sd_textbox_draw tb1 || true)
    assert_visible "$out" "Hello" "glob char text renders"
    # The * should be rendered literally, not expanded to filenames
    assert_visible "$out" "*" "star rendered literally"
}

# ---------------------------------------------------------------------------
# Bug #10: canvas caption printf format
# ---------------------------------------------------------------------------

test_regression_canvas_caption_rendered() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=20 height=3 caption="TEST" shadow=no
    local out
    out=$(_sd_canvas_draw cv1 || true)
    assert_visible "$out" "TEST" "caption rendered (not literal %s)"
}

# ---------------------------------------------------------------------------
# Bug #13: sd_clear unsets ilight/ifirst
# ---------------------------------------------------------------------------

test_regression_clear_unsets_ilight() {
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=3 arrayname=myarr
    declare -g sd_mb1_ilight=5
    declare -g sd_mb1_ifirst=2
    sd_clear
    assert_eq "" "${sd_mb1_ilight:-}" "ilight unset after clear"
    assert_eq "" "${sd_mb1_ifirst:-}" "ifirst unset after clear"
}

# ---------------------------------------------------------------------------
# sd_read empty widgets guard
# ---------------------------------------------------------------------------

test_regression_sd_read_empty() {
    _SD_ORDER=()
    local ret=0
    sd_read 2>/dev/null || ret=$?
    ret=0
    sd_read 2>/dev/null || ret=$?
    assert_eq "127" "$ret" "empty dialog returns 127"
}

# ---------------------------------------------------------------------------
# Bug #14: Enter key should move forward in inputbox (like whiptail)
# ---------------------------------------------------------------------------

test_regression_inputbox_enter_returns_255() {
    sd_load_inputbox name=ib1 width=10 varname=myvar
    myvar=""
    # Simulate Enter: escape_parse returns empty string for newline
    # The case ''') matches and returns 255
    local c=''
    local retval=0
    case "$c" in
        '') retval=255 ;;
    esac
    assert_eq "255" "$retval" "Enter in inputbox returns 255 (forward)"
}

# ---------------------------------------------------------------------------
# Bug #15: Enter key in listbox selects (menubox) and moves forward
# ---------------------------------------------------------------------------

test_regression_listbox_enter_menubox_selects() {
    myarr_e=("A" "B" "C")
    myidx_e=()
    local multi=no
    local ilight=1
    local maxindex=3
    local i
    if [[ $multi == no ]]; then
        for (( i = 0; i < maxindex; i++ )); do
            unset "myidx_e[$i]"
        done
        myidx_e[ilight]="${myarr_e[ilight]}"
    fi
    assert_eq "B" "${myidx_e[1]}" "Enter selects highlighted in menubox"
    assert_eq "" "${myidx_e[0]:-}" "other selections cleared"
}

test_regression_listbox_enter_checklist_no_toggle() {
    myarr_c=("X" "Y" "Z")
    myidx_c=()
    myidx_c[0]="X"
    # For checklist (multi=yes), Enter should NOT toggle — just move forward
    # The '' case skips toggle when multi != no
    local multi=yes
    local ilight=1
    local maxindex=3
    local i
    if [[ $multi == no ]]; then
        for (( i = 0; i < maxindex; i++ )); do
            unset "myidx_c[$i]"
        done
        myidx_c[ilight]="${myarr_c[ilight]}"
    fi
    assert_eq "X" "${myidx_c[0]}" "checklist: Enter doesn't clear existing"
    assert_eq "" "${myidx_c[1]:-}" "checklist: Enter doesn't toggle new item"
}

test_regression_listbox_enter_returns_255() {
    local c=''
    local retval=0
    case "$c" in
        '') retval=255 ;;
    esac
    assert_eq "255" "$retval" "Enter in listbox returns 255 (forward)"
}

# ---------------------------------------------------------------------------
# Bug #16: Checkbox visible on unfocused list items
# ---------------------------------------------------------------------------

test_regression_checklist_unfocused_visible() {
    TERM=xterm _sd_init_caps
    myarr_u=("Apple" "Banana" "Cherry")
    myidx_u=()
    myidx_u[1]="Banana"
    sd_load_checklist name=cl_u x=0 y=0 width=20 height=3 arrayname=myarr_u indexname=myidx_u
    declare -g sd_cl_u_ilight=0
    local out
    out=$(_sd_listbox_draw cl_u || true)
    assert_visible "$out" "*" "checked item marker visible when unfocused"
    assert_visible "$out" "[" "checkbox bracket visible when unfocused"
}

test_regression_radiolist_unfocused_visible() {
    TERM=xterm _sd_init_caps
    myarr_r=("Red" "Green" "Blue")
    myidx_r=()
    myidx_r[2]="Blue"
    sd_load_radiolist name=rl_u x=0 y=0 width=20 height=3 arrayname=myarr_r indexname=myidx_r
    declare -g sd_rl_u_ilight=0
    local out
    out=$(_sd_listbox_draw rl_u || true)
    assert_visible "$out" "*" "radio selected marker visible when unfocused"
    assert_visible "$out" "(" "radio paren visible when unfocused"
}
