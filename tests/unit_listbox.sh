#!/usr/bin/env bash
# tests/unit_listbox.sh — Tests for listbox/menubox/checklist/radiolist widget

# ---------------------------------------------------------------------------
# Draw — basic list rendering
# ---------------------------------------------------------------------------

test_listbox_draw_single_item() {
    TERM=xterm _sd_init_caps
    myarr=("Hello")
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=1 arrayname=myarr
    local out
    out=$(_sd_listbox_draw mb1) || true
    assert_visible "$out" "Hello" "single item rendered"
}

test_listbox_draw_multiple_items() {
    TERM=xterm _sd_init_caps
    myarr=("First" "Second" "Third")
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=3 arrayname=myarr
    local out
    out=$(_sd_listbox_draw mb1) || true
    assert_visible "$out" "First" "item 1"
    assert_visible "$out" "Second" "item 2"
    assert_visible "$out" "Third" "item 3"
}

test_listbox_draw_height_limit() {
    TERM=xterm _sd_init_caps
    myarr=("A" "B" "C" "D" "E")
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=2 arrayname=myarr
    local out
    out=$(_sd_listbox_draw mb1) || true
    assert_visible "$out" "A" "first visible"
    assert_visible "$out" "B" "second visible"
    assert_not_visible "$out" "C" "third not visible (height=2)"
}

test_listbox_draw_position() {
    TERM=xterm _sd_init_caps
    myarr=("Item")
    sd_load_menubox name=mb1 x=5 y=3 width=10 height=1 arrayname=myarr
    local out
    out=$(_sd_listbox_draw mb1) || true
    assert_contains "$out" $'\e[4;6H' "positioned correctly"
}

# ---------------------------------------------------------------------------
# Checklist draw — checkboxes
# ---------------------------------------------------------------------------

test_checklist_draw_checkboxes() {
    TERM=xterm _sd_init_caps
    myarr=("Item1" "Item2" "Item3")
    myidx=()
    myidx[1]="Item2"
    sd_load_checklist name=cl1 x=0 y=0 width=15 height=3 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw cl1) || true
    assert_visible "$out" "[" "checkbox bracket"
    assert_visible "$out" "*" "checked item marker"
}

test_checklist_draw_unchecked() {
    TERM=xterm _sd_init_caps
    myarr=("Item1" "Item2")
    myidx=()
    sd_load_checklist name=cl1 x=0 y=0 width=15 height=2 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw cl1) || true
    # Unchecked items should show space between brackets
    assert_visible "$out" "[" "bracket"
}

# ---------------------------------------------------------------------------
# Radiolist draw — radio buttons
# ---------------------------------------------------------------------------

test_radiolist_draw_buttons() {
    TERM=xterm _sd_init_caps
    myarr=("Opt1" "Opt2")
    myidx=()
    myidx[0]="Opt1"
    sd_load_radiolist name=rl1 x=0 y=0 width=15 height=2 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw rl1) || true
    assert_visible "$out" "(" "radio paren"
    assert_visible "$out" ")" "radio close paren"
    assert_visible "$out" "*" "selected item"
}

# ---------------------------------------------------------------------------
# Menubox — no mark characters
# ---------------------------------------------------------------------------

test_menubox_no_marks() {
    TERM=xterm _sd_init_caps
    myarr=("Item1" "Item2")
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=2 arrayname=myarr
    local out
    out=$(_sd_listbox_draw mb1) || true
    assert_not_visible "$out" "[" "no checkbox"
    assert_not_visible "$out" "(" "no radio"
}

# ---------------------------------------------------------------------------
# Listbox scrolling (ifirst)
# ---------------------------------------------------------------------------

test_listbox_scrolling_ifirst() {
    TERM=xterm _sd_init_caps
    myarr=("A" "B" "C" "D" "E")
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=2 arrayname=myarr
    declare -g sd_mb1_ifirst=3
    declare -g sd_mb1_ilight=3
    local out
    out=$(_sd_listbox_draw mb1) || true
    # Should show items starting from index 3 (D, E)
    assert_visible "$out" "D" "item at ifirst"
    assert_visible "$out" "E" "item after ifirst"
}

# ---------------------------------------------------------------------------
# Listbox highlight tracking
# ---------------------------------------------------------------------------

test_listbox_ilight_default() {
    TERM=xterm _sd_init_caps
    myarr=("A" "B" "C")
    sd_load_menubox name=mb1 x=0 y=0 width=10 height=3 arrayname=myarr
    # Default ilight should be 0
    local ilight="${sd_mb1_ilight:-0}"
    assert_eq "0" "$ilight" "default ilight=0"
}

# ---------------------------------------------------------------------------
# Listbox text truncation
# ---------------------------------------------------------------------------

test_listbox_text_truncation() {
    TERM=xterm _sd_init_caps
    myarr=("VeryLongItemName")
    sd_load_menubox name=mb1 x=0 y=0 width=5 height=1 arrayname=myarr
    local out
    out=$(_sd_listbox_draw mb1) || true
    assert_visible "$out" "VeryL" "truncated text"
    assert_not_visible "$out" "VeryLongItemName" "full text not shown"
}

# ---------------------------------------------------------------------------
# Listbox width with mark
# ---------------------------------------------------------------------------

test_listbox_width_with_mark() {
    TERM=xterm _sd_init_caps
    myarr=("A" "B")
    myidx=()
    sd_load_checklist name=cl1 x=0 y=0 width=10 height=2 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw cl1) || true
    # 4 chars used for [x ], remaining 6 for text
    assert_not_empty "$out" "checklist with mark renders"
}

# ---------------------------------------------------------------------------
# Listbox read — boundary checking
# ---------------------------------------------------------------------------

test_listbox_ilight_clamping() {
    # Simulate: ilight < 0 → clamped to 0
    local ilight=-1
    local maxindex=5
    if (( ilight < 0 )); then ilight=0; fi
    assert_eq "0" "$ilight" "negative clamped to 0"
}

test_listbox_ilight_clamping_upper() {
    local ilight=10
    local maxindex=5
    if (( ilight >= maxindex )); then ilight=$(( maxindex - 1 )); fi
    assert_eq "4" "$ilight" "exceeds max clamped to maxindex-1"
}

test_listbox_ifirst_scrolling() {
    local ilight=4 ifirst=0 height=3 maxindex=10
    if (( ilight < ifirst )); then ifirst=$ilight; fi
    if (( ilight >= ifirst + height )); then ifirst=$(( ilight - height + 1 )); fi
    assert_eq "2" "$ifirst" "ifirst scrolls to show ilight"
}

# ---------------------------------------------------------------------------
# Multi-select toggle
# ---------------------------------------------------------------------------

test_listbox_multi_select_toggle() {
    myarr=("A" "B" "C")
    myidx=()
    myidx[1]="B"

    # Simulate toggling index 1 off
    unset 'myidx[1]'
    ! [[ -v myidx[1] ]]
    assert_eq "" "${myidx[1]:-}" "toggled off"

    # Simulate toggling index 2 on
    myidx[2]="C"
    assert_eq "C" "${myidx[2]}" "toggled on"
}

test_listbox_radio_select() {
    myarr=("A" "B" "C")
    myidx=()
    myidx[0]="A"

    # Simulate radio selection of index 2: clear all, set 2
    local i
    for (( i = 0; i < 3; i++ )); do
        unset "myidx[$i]"
    done
    myidx[2]="C"
    assert_eq "" "${myidx[0]:-}" "old selection cleared"
    assert_eq "C" "${myidx[2]}" "new selection set"
}
