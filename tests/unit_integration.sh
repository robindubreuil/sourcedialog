#!/usr/bin/env bash
# tests/unit_integration.sh — Integration tests for complete dialog flows

# ---------------------------------------------------------------------------
# Example 1 recreation — OS chooser dialog
# ---------------------------------------------------------------------------

test_example1_widget_count() {
    TERM=xterm _sd_init_caps
    array=("Linux" "NetBSD" "OS/2" "WIN NT" "PCDOS" "MSDOS")
    comment=

    sd_load_canvas     name=cvmain   x=13 y=4  width=51 height=16
    sd_load_textbox    name=tbtext   x=15 y=5  text="Choose the OS you like"
    sd_load_frame      name=cvos     x=15 y=6  width=47 height=6
    sd_load_menubox    name=mbos     x=17 y=7  width=43 height=4 arrayname=array
    sd_load_textbox    name=tbwhy    x=15 y=13 text="Your comment here..."
    sd_load_frame      name=frcomm   x=15 y=14 width=47 height=3
    sd_load_inputbox   name=ibcomm   x=16 y=15 width=45 varname=comment
    sd_load_pushbutton name=pbok     x=27 y=18 caption="  OK  "
    sd_load_pushbutton name=pbcancel x=42 y=18 caption="Cancel"

    assert_eq "9" "${#_SD_ORDER[@]}" "example1 has 9 widgets"
    assert_eq "canvas" "${_SD_TYPES[cvmain]}"
    assert_eq "textbox" "${_SD_TYPES[tbtext]}"
    assert_eq "canvas" "${_SD_TYPES[cvos]}"  # frame is canvas
    assert_eq "listbox" "${_SD_TYPES[mbos]}"
    assert_eq "inputbox" "${_SD_TYPES[ibcomm]}"
    assert_eq "pushbutton" "${_SD_TYPES[pbok]}"
    assert_eq "pushbutton" "${_SD_TYPES[pbcancel]}"
}

test_example1_draw() {
    TERM=xterm _sd_init_caps
    array=("Linux" "NetBSD" "OS/2" "WIN NT" "PCDOS" "MSDOS")
    comment=

    sd_load_canvas     name=cvmain   x=13 y=4  width=51 height=16
    sd_load_textbox    name=tbtext   x=15 y=5  text="Choose the OS you like"
    sd_load_frame      name=cvos     x=15 y=6  width=47 height=6
    sd_load_menubox    name=mbos     x=17 y=7  width=43 height=4 arrayname=array
    sd_load_textbox    name=tbwhy    x=15 y=13 text="Your comment here..."
    sd_load_frame      name=frcomm   x=15 y=14 width=47 height=3
    sd_load_inputbox   name=ibcomm   x=16 y=15 width=45 varname=comment
    sd_load_pushbutton name=pbok     x=27 y=18 caption="  OK  "
    sd_load_pushbutton name=pbcancel x=42 y=18 caption="Cancel"

    local out
    out=$(sd_draw) || true
    assert_not_empty "$out" "draw produces output"
    assert_visible "$out" "Choose the OS you like" "prompt text visible"
    assert_visible "$out" "Linux" "first menu item"
    assert_visible "$out" "OK" "OK button visible"
    assert_visible "$out" "Cancel" "Cancel button visible"
}

# ---------------------------------------------------------------------------
# Example 3 recreation — account creation (complex)
# ---------------------------------------------------------------------------

test_example3_all_widget_types() {
    TERM=xterm _sd_init_caps
    array_loc=("Afghanistan" "Albania")
    array_gender=("Male" "Female")
    password=
    repassword=

    sd_load_canvas      name=cvmain x=4 y=1 width=70 height=21 caption=" CREATE YOUR ACCOUNT "
    sd_load_textbox     name=tbmail x=9 y=3 text="Email Address: "
    sd_load_inputbox    name=ibmail x=24 y=3 width=45 varname=mail
    sd_load_passwordbox name=pbpass x=24 y=4 width=45 varname=password
    sd_load_menubox     name=mbloc  x=25 y=8 width=43 arrayname=array_loc
    sd_load_radiolist   name=rlgender x=24 y=13 width=10 height=2 arrayname=array_gender indexname=index_gender
    sd_load_pushbutton  name=pbcreate x=30 y=20 caption="Create my account"

    assert_eq "7" "${#_SD_ORDER[@]}" "7 widgets"
}

# ---------------------------------------------------------------------------
# sd_clear multi-page flow
# ---------------------------------------------------------------------------

test_multipage_flow() {
    TERM=xterm _sd_init_caps

    # Page 1
    sd_load_canvas name=cv1 x=0 y=0 width=20 height=5
    sd_load_pushbutton name=ok1 caption=OK
    sd_pbok1_push() { return 0; }
    assert_eq "2" "${#_SD_ORDER[@]}" "page 1"

    sd_clear

    # Page 2 — verify page 1 stuff is gone
    assert_eq "" "${_SD_TYPES[cv1]:-}" "page 1 type cleared"
    assert_eq "" "${sd_ok1_caption:-}" "page 1 prop cleared"

    # Page 2
    sd_load_canvas name=cv2 x=0 y=0 width=20 height=5
    sd_load_textbox name=tb1 text="Page 2"
    assert_eq "2" "${#_SD_ORDER[@]}" "page 2"
    assert_not_contains "${_SD_ORDER[*]}" "cv1" "cv1 not in order"
}

# ---------------------------------------------------------------------------
# Theme customization
# ---------------------------------------------------------------------------

test_theme_customization() {
    TERM=xterm _sd_init_caps
    _SD_BG=2
    _SD_FRAME_BG=0
    _SD_BTN_SEL_BG=2

    sd_load_pushbutton name=pb1 x=0 y=0 caption="Test"
    local out
    out=$(_sd_pushbutton_draw pb1 selection) || true
    assert_contains "$out" $'\e[42m' "custom btn sel bg color"
}

# ---------------------------------------------------------------------------
# Edge case: empty dialog
# ---------------------------------------------------------------------------

test_draw_empty_dialog() {
    TERM=xterm _sd_init_caps
    local out
    out=$(sd_draw) || true
    assert_not_empty "$out" "empty dialog still clears screen"
}

# ---------------------------------------------------------------------------
# Widget with all default values
# ---------------------------------------------------------------------------

test_widget_defaults() {
    sd_load_textbox name=tb1
    assert_eq "" "${sd_tb1_x:-}" "default x"
    assert_eq "" "${sd_tb1_y:-}" "default y"
    assert_eq "" "${sd_tb1_text:-}" "default text"
}

# ---------------------------------------------------------------------------
# Callback naming convention
# ---------------------------------------------------------------------------

test_callback_naming() {
    sd_load_pushbutton name=mybutton caption=Go
    # The callback should be: sd_mybutton_push
    # We can define it and verify it's callable
    sd_mybutton_push() { return 42; }
    local ret=0; sd_mybutton_push || ret=$?
    assert_eq "42" "$ret" "custom callback return value"
}

# ---------------------------------------------------------------------------
# Large array handling
# ---------------------------------------------------------------------------

test_large_array() {
    TERM=xterm _sd_init_caps
    largearr=()
    for (( i = 0; i < 100; i++ )); do
        largearr+=("Item $i")
    done
    sd_load_menubox name=mb1 x=0 y=0 width=15 height=5 arrayname=largearr
    assert_eq "100" "${#largearr[@]}" "100 items in array"
    local out
    out=$(_sd_listbox_draw mb1) || true
    assert_visible "$out" "Item 0" "first item visible"
}

# ---------------------------------------------------------------------------
# Regression: sd_names syncs with _SD_ORDER
# ---------------------------------------------------------------------------

test_sd_names_sync() {
    sd_load_canvas name=alpha
    sd_load_textbox name=beta text=hi
    sd_load_pushbutton name=gamma caption=OK
    local joined; IFS=' '; joined="${sd_names[*]}"
    assert_eq "alpha beta gamma" "$joined" "sd_names matches order"
    assert_eq "${#_SD_ORDER[@]}" "${#sd_names[@]}" "same length"
}
