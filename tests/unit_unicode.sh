#!/usr/bin/env bash
# tests/unit_unicode.sh — Tests for unicode/256-color visual mode

_sd_reinit_unicode() {
    _sd_reinit
    _SD_STYLE=unicode
    _SD_256COLOR=no
    _SD_SHADOW_BG=
}

# ---------------------------------------------------------------------------
# Unicode style detection
# ---------------------------------------------------------------------------

test_unicode_auto_detect_utf8() {
    _sd_reinit_unicode
    LANG=en_US.UTF-8 _SD_STYLE=auto TERM=xterm _sd_init_caps
    assert_eq "1" "$_SD_UNICODE" "auto-detect UTF-8 locale"
}

test_unicode_auto_detect_non_utf8() {
    _sd_reinit_unicode
    LANG=C _SD_STYLE=auto TERM=xterm _sd_init_caps
    assert_eq "0" "$_SD_UNICODE" "auto-detect non-UTF-8 locale"
}

test_unicode_explicit_unicode() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    assert_eq "1" "$_SD_UNICODE" "explicit unicode style"
}

test_unicode_explicit_legacy() {
    _sd_reinit_unicode
    _SD_STYLE=legacy TERM=xterm _sd_init_caps
    assert_eq "0" "$_SD_UNICODE" "explicit legacy style"
}

# ---------------------------------------------------------------------------
# Unicode box characters
# ---------------------------------------------------------------------------

test_unicode_box_chars_rounded() {
    _sd_reinit_unicode
    _SD_CORNER=rounded TERM=xterm _sd_init_caps
    assert_eq "╯" "${_SD_BOX[0]}" "rounded bottom-right"
    assert_eq "╮" "${_SD_BOX[1]}" "rounded top-right"
    assert_eq "╭" "${_SD_BOX[2]}" "rounded top-left"
    assert_eq "╰" "${_SD_BOX[3]}" "rounded bottom-left"
    assert_eq "─" "${_SD_BOX[4]}" "horizontal"
    assert_eq "│" "${_SD_BOX[5]}" "vertical"
}

test_unicode_box_chars_square() {
    _sd_reinit_unicode
    _SD_CORNER=square TERM=xterm _sd_init_caps
    assert_eq "┘" "${_SD_BOX[0]}" "square bottom-right"
    assert_eq "┐" "${_SD_BOX[1]}" "square top-right"
    assert_eq "┌" "${_SD_BOX[2]}" "square top-left"
    assert_eq "└" "${_SD_BOX[3]}" "square bottom-left"
    assert_eq "─" "${_SD_BOX[4]}" "horizontal"
    assert_eq "│" "${_SD_BOX[5]}" "vertical"
}

test_unicode_smacs_disabled() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    assert_eq "" "${_SD_CAPS[smacs]}" "smacs empty in unicode mode"
    assert_eq "" "${_SD_CAPS[rmacs]}" "rmacs empty in unicode mode"
}

# ---------------------------------------------------------------------------
# Unicode markers
# ---------------------------------------------------------------------------

test_unicode_check_markers() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    assert_eq "■" "$_SD_CHECK_ON" "checkbox on"
    assert_eq "□" "$_SD_CHECK_OFF" "checkbox off"
}

test_unicode_radio_markers() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    assert_eq "◉" "$_SD_RADIO_ON" "radio on"
    assert_eq "○" "$_SD_RADIO_OFF" "radio off"
}

test_unicode_mark_width() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    assert_eq "2" "$_SD_MARK_WIDTH" "unicode mark width is 2"
}

test_legacy_mark_width() {
    _sd_reinit
    _SD_STYLE=legacy TERM=xterm _sd_init_caps
    assert_eq "4" "$_SD_MARK_WIDTH" "legacy mark width is 4"
}

# ---------------------------------------------------------------------------
# Unicode buttons
# ---------------------------------------------------------------------------

test_unicode_button_brackets() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    assert_eq "[" "$_SD_BTN_OPEN" "unicode button open"
    assert_eq "]" "$_SD_BTN_CLOSE" "unicode button close"
}

test_legacy_button_brackets() {
    _sd_reinit
    _SD_STYLE=legacy TERM=xterm _sd_init_caps
    assert_eq "<" "$_SD_BTN_OPEN" "legacy button open"
    assert_eq ">" "$_SD_BTN_CLOSE" "legacy button close"
}

# ---------------------------------------------------------------------------
# Unicode scroll indicators
# ---------------------------------------------------------------------------

test_unicode_scroll_chars() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    assert_eq "▲" "$_SD_SCROLL_UP" "scroll up"
    assert_eq "▼" "$_SD_SCROLL_DOWN" "scroll down"
}

test_legacy_scroll_chars() {
    _sd_reinit
    _SD_STYLE=legacy TERM=xterm _sd_init_caps
    assert_eq "^" "$_SD_SCROLL_UP" "legacy scroll up"
    assert_eq "v" "$_SD_SCROLL_DOWN" "legacy scroll down"
}

# ---------------------------------------------------------------------------
# Unicode canvas rendering
# ---------------------------------------------------------------------------

test_unicode_canvas_draw() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    sd_load_canvas name=ucv1 x=0 y=0 width=10 height=3 shadow=no
    local out
    out=$(_sd_canvas_draw ucv1) || true
    assert_visible "$out" "╭" "rounded top-left corner"
    assert_visible "$out" "╮" "rounded top-right corner"
    assert_visible "$out" "╰" "rounded bottom-left corner"
    assert_visible "$out" "╯" "rounded bottom-right corner"
    assert_visible "$out" "│" "vertical bar"
    assert_visible "$out" "─" "horizontal bar"
}

test_unicode_canvas_caption() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    sd_load_canvas name=ucv2 x=0 y=0 width=20 height=3 caption="TITLE"
    local out
    out=$(_sd_canvas_draw ucv2) || true
    assert_visible "$out" "TITLE" "caption rendered in unicode frame"
}

test_unicode_canvas_square() {
    _sd_reinit_unicode
    _SD_STYLE=unicode _SD_CORNER=square TERM=xterm _sd_init_caps
    sd_load_canvas name=ucv3 x=0 y=0 width=10 height=3 shadow=no
    local out
    out=$(_sd_canvas_draw ucv3) || true
    assert_visible "$out" "┌" "square top-left"
    assert_visible "$out" "┐" "square top-right"
    assert_visible "$out" "└" "square bottom-left"
    assert_visible "$out" "┘" "square bottom-right"
}

# ---------------------------------------------------------------------------
# Unicode listbox rendering
# ---------------------------------------------------------------------------

test_unicode_checklist_draw() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    myarr=("Item1" "Item2" "Item3")
    myidx=()
    myidx[1]="Item2"
    sd_load_checklist name=ucl1 x=0 y=0 width=15 height=3 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw ucl1) || true
    assert_visible "$out" "■" "checked item shows ■"
    assert_visible "$out" "□" "unchecked item shows □"
    assert_visible "$out" "Item1" "item1 text"
    assert_visible "$out" "Item2" "item2 text"
}

test_unicode_radiolist_draw() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    myarr=("Opt1" "Opt2")
    myidx=()
    myidx[0]="Opt1"
    sd_load_radiolist name=url1 x=0 y=0 width=15 height=2 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw url1) || true
    assert_visible "$out" "◉" "selected radio shows ◉"
    assert_visible "$out" "○" "unselected radio shows ○"
}

test_unicode_listbox_width() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    myarr=("TestItem")
    myidx=()
    sd_load_checklist name=ucl2 x=0 y=0 width=10 height=1 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw ucl2) || true
    assert_visible "$out" "□" "check marker visible"
}

# ---------------------------------------------------------------------------
# Unicode scroll indicators rendering
# ---------------------------------------------------------------------------

test_unicode_scroll_down_indicator() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    myarr=("A" "B" "C" "D" "E")
    sd_load_menubox name=usc1 x=0 y=0 width=10 height=2 arrayname=myarr
    declare -g sd_usc1_ifirst=0
    declare -g sd_usc1_ilight=0
    local out
    out=$(_sd_listbox_draw usc1) || true
    assert_visible "$out" "▼" "scroll down indicator shown"
}

test_unicode_scroll_up_indicator() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    myarr=("A" "B" "C" "D" "E")
    sd_load_menubox name=usc2 x=0 y=0 width=10 height=2 arrayname=myarr
    declare -g sd_usc2_ifirst=3
    declare -g sd_usc2_ilight=3
    local out
    out=$(_sd_listbox_draw usc2) || true
    assert_visible "$out" "▲" "scroll up indicator shown"
}

test_unicode_no_scroll_when_all_fit() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    myarr=("A" "B")
    sd_load_menubox name=usc3 x=0 y=0 width=10 height=3 arrayname=myarr
    declare -g sd_usc3_ifirst=0
    declare -g sd_usc3_ilight=0
    local out
    out=$(_sd_listbox_draw usc3) || true
    assert_not_visible "$out" "▲" "no scroll up when all fit"
    assert_not_visible "$out" "▼" "no scroll down when all fit"
}

# ---------------------------------------------------------------------------
# Unicode pushbutton rendering
# ---------------------------------------------------------------------------

test_unicode_pushbutton_draw() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    sd_load_pushbutton name=upb1 x=5 y=3 caption="OK"
    local out
    out=$(_sd_pushbutton_draw upb1) || true
    assert_visible "$out" "[" "unicode left bracket"
    assert_visible "$out" "]" "unicode right bracket"
    assert_visible "$out" "OK" "caption text"
}

test_unicode_pushbutton_selected() {
    _sd_reinit_unicode
    _SD_STYLE=unicode TERM=xterm _sd_init_caps
    sd_load_pushbutton name=upb2 x=5 y=3 caption="Cancel"
    local out
    out=$(_sd_pushbutton_draw upb2 selection) || true
    assert_visible "$out" "[" "selected left bracket"
    assert_visible "$out" "]" "selected right bracket"
    assert_visible "$out" "Cancel" "selected caption"
}

# ---------------------------------------------------------------------------
# 256-color support
# ---------------------------------------------------------------------------

test_256color_detection_auto() {
    _sd_reinit
    _SD_256COLOR=auto TERM=xterm-256color _sd_init_caps
    assert_eq "1" "$_SD_HAS_256" "detect 256-color from TERM"
}

test_256color_detection_no() {
    _sd_reinit
    _SD_256COLOR=no TERM=xterm _sd_init_caps
    assert_eq "0" "$_SD_HAS_256" "force no 256-color"
}

test_256color_fg() {
    _sd_reinit
    _SD_256COLOR=yes TERM=xterm _sd_init_caps
    local out
    out=$(_sd_fg 3)
    assert_eq $'\e[38;5;3m' "$out" "256-color fg sequence"
}

test_256color_bg() {
    _sd_reinit
    _SD_256COLOR=yes TERM=xterm _sd_init_caps
    local out
    out=$(_sd_bg 4)
    assert_eq $'\e[48;5;4m' "$out" "256-color bg sequence"
}

test_256color_shadow_bg() {
    _sd_reinit
    _SD_256COLOR=yes TERM=xterm _sd_init_caps
    assert_eq "236" "$_SD_SHADOW_BG" "shadow uses dark gray in 256-color"
}

test_256color_shadow_render() {
    _sd_reinit
    _SD_256COLOR=yes TERM=xterm _sd_init_caps
    sd_load_canvas name=scv1 x=0 y=0 width=10 height=3 shadow=yes
    local out
    out=$(_sd_canvas_draw scv1) || true
    assert_contains "$out" $'\e[48;5;236m' "shadow uses 256-color dark gray"
}

# ---------------------------------------------------------------------------
# Legacy mode still works correctly
# ---------------------------------------------------------------------------

test_legacy_canvas_acs() {
    _sd_reinit
    _SD_STYLE=legacy TERM=xterm _sd_init_caps
    sd_load_canvas name=lcv1 x=0 y=0 width=10 height=3 shadow=no
    local out
    out=$(_sd_canvas_draw lcv1) || true
    assert_contains "$out" "${_SD_CAPS[smacs]}" "legacy mode uses ACS"
}

test_legacy_markers() {
    _sd_reinit
    _SD_STYLE=legacy TERM=xterm _sd_init_caps
    myarr=("A" "B")
    myidx=()
    myidx[0]="A"
    sd_load_checklist name=lcl1 x=0 y=0 width=15 height=2 arrayname=myarr indexname=myidx
    local out
    out=$(_sd_listbox_draw lcl1) || true
    assert_visible "$out" "[" "legacy checkbox bracket"
    assert_visible "$out" "*" "legacy checked marker"
}
