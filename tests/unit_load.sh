#!/usr/bin/env bash
# tests/unit_load.sh — Tests for sd_load and sd_load_* functions

# ---------------------------------------------------------------------------
# sd_load basic registration
# ---------------------------------------------------------------------------

test_load_single_widget() {
    sd_load name=w1 type=canvas x=5 y=3
    assert_eq "w1" "${_SD_ORDER[0]}" "first widget in order"
    assert_eq "canvas" "${_SD_TYPES[w1]}" "type stored"
    assert_eq "5" "${sd_w1_x}" "prop x stored"
    assert_eq "3" "${sd_w1_y}" "prop y stored"
    local joined; IFS=' '; joined="${sd_names[*]}"
    assert_eq "w1" "$joined" "sd_names array"
}

test_load_multiple_widgets() {
    sd_load name=w1 type=canvas
    sd_load name=w2 type=textbox text=hello
    sd_load name=w3 type=pushbutton caption=OK
    assert_eq "3" "${#_SD_ORDER[@]}" "order count"
    assert_eq "w1 w2 w3" "${_SD_ORDER[*]}" "order"
    assert_eq "canvas" "${_SD_TYPES[w1]}"
    assert_eq "textbox" "${_SD_TYPES[w2]}"
    assert_eq "pushbutton" "${_SD_TYPES[w3]}"
}

test_load_props_with_equals() {
    sd_load name=w1 type=textbox text="hello=world"
    assert_eq "hello=world" "${sd_w1_text}" "prop with = in value"
}

test_load_empty_props() {
    sd_load name=w1 type=canvas
    assert_eq "" "${sd_w1_x:-}" "missing prop is empty"
}

test_load_prop_list() {
    sd_load name=w1 type=canvas x=5 y=3 width=10 height=5
    local plist=${_SD_PROP_LIST[w1]}
    assert_contains "$plist" "x " "prop list contains x"
    assert_contains "$plist" "y " "prop list contains y"
    assert_contains "$plist" "width " "prop list contains width"
    assert_contains "$plist" "height " "prop list contains height"
}

# ---------------------------------------------------------------------------
# sd_load_* wrapper functions
# ---------------------------------------------------------------------------

test_load_canvas() {
    sd_load_canvas name=cv1 x=5 y=3 width=40 height=10
    assert_eq "canvas" "${_SD_TYPES[cv1]}" "canvas type"
    assert_eq "5" "${sd_cv1_x}" "canvas x"
}

test_load_frame() {
    sd_load_frame name=fr1 x=5 y=3 width=40 height=10
    assert_eq "canvas" "${_SD_TYPES[fr1]}" "frame is canvas type"
    assert_eq "no" "${sd_fr1_shadow}" "frame shadow=no"
    assert_eq "concave" "${sd_fr1_frame}" "frame frame=concave"
}

test_load_textbox() {
    sd_load_textbox name=tb1 text="Hello World"
    assert_eq "textbox" "${_SD_TYPES[tb1]}" "textbox type"
    assert_eq "Hello World" "${sd_tb1_text}" "textbox text"
}

test_load_pushbutton() {
    sd_load_pushbutton name=pb1 caption="OK"
    assert_eq "pushbutton" "${_SD_TYPES[pb1]}" "pushbutton type"
    assert_eq "OK" "${sd_pb1_caption}" "pushbutton caption"
}

test_load_inputbox() {
    sd_load_inputbox name=ib1 width=20 varname=myvar
    assert_eq "inputbox" "${_SD_TYPES[ib1]}" "inputbox type"
    assert_eq "20" "${sd_ib1_width}" "inputbox width"
    assert_eq "myvar" "${sd_ib1_varname}" "inputbox varname"
}

test_load_passwordbox() {
    sd_load_passwordbox name=pw1 width=20 varname=mypass
    assert_eq "inputbox" "${_SD_TYPES[pw1]}" "passwordbox is inputbox type"
    assert_eq "yes" "${sd_pw1_password}" "password flag"
}

test_load_menubox() {
    sd_load_menubox name=mb1 width=30 height=5 arrayname=myarr
    assert_eq "listbox" "${_SD_TYPES[mb1]}" "menubox is listbox type"
}

test_load_checklist() {
    sd_load_checklist name=cl1 width=30 height=5 arrayname=myarr indexname=myidx
    assert_eq "listbox" "${_SD_TYPES[cl1]}" "checklist is listbox type"
    assert_eq "check" "${sd_cl1_mark}" "checklist mark"
    assert_eq "yes" "${sd_cl1_multi}" "checklist multi=yes"
}

test_load_radiolist() {
    sd_load_radiolist name=rl1 width=30 height=5 arrayname=myarr indexname=myidx
    assert_eq "listbox" "${_SD_TYPES[rl1]}" "radiolist is listbox type"
    assert_eq "radio" "${sd_rl1_mark}" "radiolist mark"
    assert_eq "no" "${sd_rl1_multi}" "radiolist multi=no"
}

test_load_preserves_order() {
    sd_load_canvas name=a
    sd_load_textbox name=b
    sd_load_pushbutton name=c
    sd_load_inputbox name=d
    sd_load_menubox name=e
    assert_eq "a b c d e" "${_SD_ORDER[*]}" "order preserved"
    local joined; IFS=' '; joined="${sd_names[*]}"
    assert_eq "a b c d e" "$joined" "sd_names matches"
}
