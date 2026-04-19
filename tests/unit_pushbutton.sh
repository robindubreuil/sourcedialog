#!/usr/bin/env bash
# tests/unit_pushbutton.sh — Tests for pushbutton widget

# ---------------------------------------------------------------------------
# Draw — normal (unselected) state
# ---------------------------------------------------------------------------

test_pushbutton_draw_basic() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=5 y=3 caption="OK"
    local out
    out=$(_sd_pushbutton_draw pb1) || true
    assert_visible "$out" "<" "left bracket"
    assert_visible "$out" ">" "right bracket"
    assert_visible "$out" "OK" "caption text"
}

test_pushbutton_draw_position() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=10 y=5 caption="OK"
    local out
    out=$(_sd_pushbutton_draw pb1) || true
    assert_contains "$out" $'\e[6;11H' "positioned at y=5, x=10"
}

test_pushbutton_draw_selected() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=5 y=3 caption="OK"
    local out
    out=$(_sd_pushbutton_draw pb1 selection) || true
    # Selected state should use _SD_BTN_SEL_* colors
    assert_visible "$out" "OK" "selected still shows caption"
}

test_pushbutton_draw_highlight_letter() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=5 y=3 caption="Cancel"
    local out
    out=$(_sd_pushbutton_draw pb1) || true
    # The first alphanumeric letter should be highlighted with a different color
    assert_visible "$out" "C" "first letter C present"
    assert_visible "$out" "ancel" "rest of caption present"
}

test_pushbutton_draw_caption_with_spaces() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=5 y=3 caption="  OK  "
    local out
    out=$(_sd_pushbutton_draw pb1) || true
    assert_visible "$out" "OK" "spaces preserved, caption text shown"
}

test_pushbutton_draw_leading_nonalpha() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=5 y=3 caption="  Next  "
    local out
    out=$(_sd_pushbutton_draw pb1) || true
    # Leading spaces, then 'N' is the first alphanumeric
    assert_visible "$out" "N" "highlighted N"
}

test_pushbutton_draw_default_position() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 caption="OK"
    local out
    out=$(_sd_pushbutton_draw pb1) || true
    assert_contains "$out" $'\e[1;1H' "default position 0,0"
}

# ---------------------------------------------------------------------------
# Draw — cursor reposition at end
# ---------------------------------------------------------------------------

test_pushbutton_draw_repositions_cursor() {
    TERM=xterm _sd_init_caps
    sd_load_pushbutton name=pb1 x=5 y=3 caption="OK"
    local out
    out=$(_sd_pushbutton_draw pb1) || true
    # After drawing, cursor should be repositioned to x+1 for highlighting
    assert_contains "$out" $'\e[4;6H' "cursor repositioned to x+1"
}
