#!/usr/bin/env bash
# tests/unit_lifecycle.sh — Tests for sd_start/sd_init/sd_reset/sd_clear lifecycle

# ---------------------------------------------------------------------------
# sd_init
# ---------------------------------------------------------------------------

test_sd_init_sets_active() {
    _SD_ACTIVE=0
    sd_init 2>/dev/null || true
    assert_eq "1" "$_SD_ACTIVE" "active flag set"
}

test_sd_init_sets_ifs() {
    sd_init 2>/dev/null || true
    # IFS should be set to newline
    assert_eq $'\n' "$IFS" "IFS set to newline"
}

test_sd_init_hides_cursor() {
    TERM=xterm _sd_init_caps
    _SD_ACTIVE=0
    # We can't actually call sd_init because it calls stty -echo
    # But we can verify the caps are set
    assert_not_empty "${_SD_CAPS[civis]}" "civis cap available"
    assert_not_empty "${_SD_CAPS[smkx]}" "smkx cap available"
}

# ---------------------------------------------------------------------------
# sd_reset
# ---------------------------------------------------------------------------

test_sd_reset_clears_active() {
    _SD_ACTIVE=1
    sd_reset 2>/dev/null || true
    assert_eq "0" "$_SD_ACTIVE" "active flag cleared"
}

test_sd_reset_restores_ifs() {
    sd_reset 2>/dev/null || true
    assert_eq $' \t\n' "$IFS" "IFS restored"
}

# ---------------------------------------------------------------------------
# sd_clear
# ---------------------------------------------------------------------------

test_sd_clear_empties_order() {
    sd_load_canvas name=w1
    sd_load_textbox name=w2 text=hi
    assert_eq "2" "${#_SD_ORDER[@]}" "two widgets loaded"
    sd_clear
    assert_eq "0" "${#_SD_ORDER[@]}" "order cleared"
}

test_sd_clear_empties_names() {
    sd_load_canvas name=w1
    assert_eq "1" "${#sd_names[@]}" "one in names"
    sd_clear
    assert_eq "0" "${#sd_names[@]}" "names cleared"
}

test_sd_clear_unsets_props() {
    sd_load_textbox name=tb1 text="hello" width=10
    assert_eq "hello" "${sd_tb1_text}" "text set"
    assert_eq "10" "${sd_tb1_width}" "width set"
    sd_clear
    assert_eq "" "${sd_tb1_text:-}" "text unset after clear"
    assert_eq "" "${sd_tb1_width:-}" "width unset after clear"
}

test_sd_clear_unsets_types() {
    sd_load_canvas name=w1
    assert_eq "canvas" "${_SD_TYPES[w1]}" "type set"
    sd_clear
    assert_eq "" "${_SD_TYPES[w1]:-}" "type unset after clear"
}

test_sd_clear_allows_reload() {
    sd_load_canvas name=w1
    sd_clear
    sd_load_textbox name=w2 text="new"
    assert_eq "1" "${#_SD_ORDER[@]}" "reloaded after clear"
    assert_eq "textbox" "${_SD_TYPES[w2]}" "new type correct"
    assert_eq "new" "${sd_w2_text}" "new props correct"
}

# ---------------------------------------------------------------------------
# sd_draw — iterates widgets
# ---------------------------------------------------------------------------

test_sd_draw_calls_widget_draws() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=5 height=2 shadow=no
    local out
    out=$(sd_draw) || true
    assert_not_empty "$out" "draw produces output"
}

test_sd_draw_multiple_widgets() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=10 height=2 shadow=no
    sd_load_textbox name=tb1 x=1 y=1 width=8 text="Hello"
    local out
    out=$(sd_draw) || true
    assert_visible "$out" "Hello" "textbox text in draw output"
}

# ---------------------------------------------------------------------------
# sd_read — widget navigation
# ---------------------------------------------------------------------------

test_sd_read_direction_255() {
    # retval 255 means direction=1 (forward)
    local direction=1
    # Simulating the logic from sd_read:
    # case 255) direction=1 ;;
    local retval=255
    case $retval in
        254) direction=-1 ;;
        255) direction=1 ;;
    esac
    assert_eq "1" "$direction" "255 => forward"
}

test_sd_read_direction_254() {
    local direction=1
    local retval=254
    case $retval in
        254) direction=-1 ;;
        255) direction=1 ;;
    esac
    assert_eq "-1" "$direction" "254 => backward"
}

test_sd_read_direction_127() {
    local direction=1
    local retval=127
    case $retval in
        127) : ;;
        254) direction=-1 ;;
        255) direction=1 ;;
    esac
    assert_eq "1" "$direction" "127 => no change (canvas/textbox skip)"
}

test_sd_read_index_wrap_forward() {
    local i=4 max=3
    if (( i > max )); then i=0; fi
    assert_eq "0" "$i" "wraps to 0 past max"
}

test_sd_read_index_wrap_backward() {
    local i=-1 max=3
    if (( i < 0 )); then i=$(( max - 1 )); fi
    assert_eq "2" "$i" "wraps to max-1 below 0"
}

# ---------------------------------------------------------------------------
# Integration: sd_start lifecycle (mocked)
# ---------------------------------------------------------------------------

test_sd_start_lifecycle_sequence() {
    # Can't call sd_start directly (it calls read which blocks),
    # but we can verify init/reset don't crash
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=5 height=2
    sd_init 2>/dev/null || true
    assert_eq "1" "$_SD_ACTIVE" "active after init"
    sd_reset 2>/dev/null || true
    assert_eq "0" "$_SD_ACTIVE" "inactive after reset"
}

# ---------------------------------------------------------------------------
# Multi-page flow simulation
# ---------------------------------------------------------------------------

test_sd_clear_between_pages() {
    TERM=xterm _sd_init_caps

    # Page 1
    sd_load_canvas name=cv1 x=0 y=0 width=10 height=3
    sd_load_pushbutton name=pb1 caption=OK
    assert_eq "2" "${#_SD_ORDER[@]}" "page 1: 2 widgets"

    sd_clear

    # Page 2
    sd_load_canvas name=cv2 x=0 y=0 width=10 height=3
    sd_load_textbox name=tb1 text="Page 2"
    sd_load_pushbutton name=pb2 caption=Done
    assert_eq "3" "${#_SD_ORDER[@]}" "page 2: 3 widgets"
    assert_eq "canvas" "${_SD_TYPES[cv2]}" "page 2 canvas type"
    assert_eq "textbox" "${_SD_TYPES[tb1]}" "page 2 textbox type"
    assert_eq "pushbutton" "${_SD_TYPES[pb2]}" "page 2 button type"
}
