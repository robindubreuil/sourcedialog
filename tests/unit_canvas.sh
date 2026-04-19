#!/usr/bin/env bash
# tests/unit_canvas.sh — Tests for canvas/frame widget drawing

# ---------------------------------------------------------------------------
# Canvas draw — basic structure
# ---------------------------------------------------------------------------

test_canvas_draw_basic() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=10 height=3
    local out
    out=$(_sd_canvas_draw cv1) || true

    # Should contain positioning and box characters
    assert_contains "$out" $'\e[' "contains escape sequences"
    assert_not_empty "$out" "canvas output not empty"
}

test_canvas_draw_with_caption() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=20 height=3 caption="TEST"
    local out
    out=$(_sd_canvas_draw cv1) || true

    assert_visible "$out" "TEST" "caption rendered"
}

test_canvas_draw_caption_truncation() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=6 height=3 caption="LONG CAPTION"
    local out
    out=$(_sd_canvas_draw cv1) || true

    # Caption should be truncated to fit width - 2 = 4 chars
    assert_not_visible "$out" "LONG CAPTION" "long caption truncated"
}

test_canvas_draw_shadow() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=10 height=3 shadow=yes
    local out
    out=$(_sd_canvas_draw cv1) || true

    # Shadow adds extra positioning — check for black bg
    assert_contains "$out" $'\e[40m' "shadow uses bg black"
}

test_canvas_draw_no_shadow() {
    TERM=xterm _sd_init_caps
    sd_load_frame name=fr1 x=0 y=0 width=10 height=3
    local out
    out=$(_sd_canvas_draw fr1) || true

    assert_not_contains "$out" $'\e[40m' "no shadow with frame"
}

test_canvas_draw_convex_frame() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=10 height=3 frame=convex shadow=no
    local out
    out=$(_sd_canvas_draw cv1) || true
    assert_not_empty "$out" "convex frame renders"
}

test_canvas_draw_concave_frame() {
    TERM=xterm _sd_init_caps
    sd_load_frame name=fr1 x=0 y=0 width=10 height=3
    local out
    out=$(_sd_canvas_draw fr1) || true
    assert_not_empty "$out" "concave frame renders"
}

test_canvas_draw_minimum_width() {
    TERM=xterm _sd_init_caps
    # width=1 should be clamped to 2
    sd_load_canvas name=cv1 x=0 y=0 width=1 height=3
    local out
    out=$(_sd_canvas_draw cv1) || true
    assert_not_empty "$out" "min width canvas renders"
}

test_canvas_draw_default_position() {
    TERM=xterm _sd_init_caps
    # No x/y specified — defaults to 0,0
    sd_load_canvas name=cv1 width=10 height=3
    local out
    out=$(_sd_canvas_draw cv1) || true
    assert_contains "$out" $'\e[1;1H' "defaults to pos 0,0"
}

test_canvas_draw_multiple_rows() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=10 height=5 shadow=no
    local out
    out=$(_sd_canvas_draw cv1) || true

    # Should have multiple cursor positioning sequences for each row
    local count
    count=$(printf '%s' "$out" | grep -o $'\e\[' | wc -l)
    assert_ge "$count" 5 "at least 5 positions for 5 rows"
}

# ---------------------------------------------------------------------------
# Canvas read — always returns 127 (not interactive)
# ---------------------------------------------------------------------------

test_canvas_read_returns_127() {
    local ret=0; _sd_canvas_read cv1 || ret=$?
    assert_eq "127" "$ret" "canvas read returns 127"
}

# ---------------------------------------------------------------------------
# Frame is a canvas variant
# ---------------------------------------------------------------------------

test_frame_is_canvas() {
    sd_load_frame name=fr1 x=0 y=0 width=10 height=3
    assert_eq "canvas" "${_SD_TYPES[fr1]}" "frame stored as canvas type"
}

test_frame_default_shadow_no() {
    sd_load_frame name=fr1 x=0 y=0 width=10 height=3
    assert_eq "no" "${sd_fr1_shadow}" "frame shadow defaults to no"
}

test_frame_default_frame_concave() {
    sd_load_frame name=fr1 x=0 y=0 width=10 height=3
    assert_eq "concave" "${sd_fr1_frame}" "frame defaults to concave"
}

# ---------------------------------------------------------------------------
# Canvas with explicit frame override
# ---------------------------------------------------------------------------

test_canvas_explicit_frame() {
    TERM=xterm _sd_init_caps
    sd_load name=cv1 type=canvas x=0 y=0 width=10 height=3 frame=convex shadow=no
    local out
    out=$(_sd_canvas_draw cv1) || true
    assert_not_empty "$out" "explicit frame renders"
}

# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

test_canvas_height_zero() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=0 y=0 width=10 height=0
    local out
    out=$(_sd_canvas_draw cv1) || true
    # height=0 means loop doesn't execute
    local stripped
    stripped=$(strip_ansi "$out")
    # Should be mostly empty or just shadow
    assert_not_contains "$stripped" "ERROR" "no crash on height=0"
}

test_canvas_draw_position_offset() {
    TERM=xterm _sd_init_caps
    sd_load_canvas name=cv1 x=5 y=3 width=10 height=2 shadow=no
    local out
    out=$(_sd_canvas_draw cv1) || true
    # First row should be at y+1=4, x+1=6
    assert_contains "$out" $'\e[4;6H' "first row at offset position"
}
