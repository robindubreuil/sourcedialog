#!/usr/bin/env bash
# tests/unit_textbox.sh — Tests for textbox widget

# ---------------------------------------------------------------------------
# Basic text rendering
# ---------------------------------------------------------------------------

test_textbox_simple() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=10 text="Hello"
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_visible "$out" "Hello" "simple text rendered"
}

test_textbox_empty_text() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=10 text=""
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_not_empty "$out" "empty text still produces output (padding)"
}

test_textbox_default_width() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 text="Hello"
    # Default width = ${#text} = 5
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_visible "$out" "Hello" "default width works"
}

test_textbox_read_returns_127() {
    local ret=0; _sd_textbox_read tb1 || ret=$?
    assert_eq "127" "$ret" "textbox read returns 127"
}

# ---------------------------------------------------------------------------
# Word wrapping
# ---------------------------------------------------------------------------

test_textbox_word_wrap() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=10 height=2 text="Hello World"
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_visible "$out" "Hello" "first word rendered"
    assert_visible "$out" "World" "second word wrapped"
}

test_textbox_newline_literal() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=20 height=3 text="Line1\\nLine2\\nLine3"
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_visible "$out" "Line1" "first line"
    assert_visible "$out" "Line2" "second line"
    assert_visible "$out" "Line3" "third line"
}

test_textbox_word_truncation() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=5 height=1 text="VeryLongWord"
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_visible "$out" "VeryL" "long word truncated to width"
    assert_not_visible "$out" "VeryLongWord" "full word not shown"
}

test_textbox_multiline_wrap() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=10 height=5 \
        text="This is a longer sentence that should wrap across multiple lines"
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_visible "$out" "This" "contains This"
    assert_visible "$out" "sentence" "contains wrapped word"
}

test_textbox_height_limit() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=5 height=1 \
        text="a b c d e f g h i j"
    local out
    out=$(_sd_textbox_draw tb1) || true
    # Only first line should appear
    assert_visible "$out" "a" "first word"
}

test_textbox_only_spaces() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=10 height=1 text="   "
    local out
    out=$(_sd_textbox_draw tb1) || true
    # Should not crash — text of only spaces should produce empty words array
    assert_not_empty "$out" "spaces-only text still produces output"
}

test_textbox_position_offset() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=5 y=3 width=10 text="Hello"
    local out
    out=$(_sd_textbox_draw tb1) || true
    assert_contains "$out" $'\e[4;6H' "positioned at y=3+1, x=5+1"
}

test_textbox_default_height() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=0 width=10 text="Hello"
    # Default height = 1
    assert_eq "1" "${sd_tb1_height:-1}" "default height is 1"
}

test_textbox_multiline_positioning() {
    TERM=xterm _sd_init_caps
    sd_load_textbox name=tb1 x=0 y=2 width=10 height=3 text="a\\nb\\nc"
    local out
    out=$(_sd_textbox_draw tb1) || true
    # Lines should be at y=3, y=4, y=5 (0-indexed + offset)
    assert_contains "$out" $'\e[3;' "line 1 position"
    assert_contains "$out" $'\e[4;' "line 2 position"
    assert_contains "$out" $'\e[5;' "line 3 position"
}
