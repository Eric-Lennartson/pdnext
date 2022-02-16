package require Tk 8.6

# bezier cords
proc redraw_cords {name, blank, op} {
    foreach wind [wm stackorder .] {
        if {[winfo class $wind] eq "PatchWindow"} {
            set canv ${wind}.c
            foreach record [$canv find withtag cord] {
                set tag [lindex [$canv gettags $record] 0]
                set coords [lreplace [$canv coords $tag] 2 end-2]
                ::pdtk_canvas::pdtk_coords {*}$coords $tag $canv
            }
        }
    }
}

trace variable ::curve_cords w redraw_cords
set ::curve_cords 1 ;# bezier cords

set dark  [file join "$::sys_guidir" "pedal" "pedal-dark.tcl"]
set light [file join "$::sys_guidir" "pedal" "pedal-light.tcl"]
source $dark
source $light

ttk::setTheme pedal-light
set theme [ttk::style theme use]
::pdwindow::debug "$theme loaded. Theming pd with $theme!\n"

# Also, it's in the prefs menu rn, but  eventually I want to make a gui dialog, where
# It becomes much easier to create and set this kinda stuff
# (This is also where the font dialog would live)

set ::themeState 1 ;# 1 for light, 0 for dark
proc updateTheme {args} {
    if {$::themeState == 0} {
        ttk::setTheme pedal-dark
    } else {
        ttk::setTheme pedal-light
    }
    foreach wind [wm stackorder .] {
        if {[winfo class $wind] eq "PatchWindow"} {
            set canv ${wind}.c
            ::pdtk_canvas::updateTheme $canv
        } elseif {[winfo class $wind] eq "PdWindow"} {
            ::pdwindow::set_colors
        }
    }
    # ::pdwindow::debug "themeState changed to $::themeState\n"
    # ::pdwindow::debug "theme changed to [ttk::style theme use]\n"
}
trace variable ::themeState w updateTheme

# softpaper
array set ::lightTheme {
    dial_background          "#DCD6C5"
    dial_track               "#fffff8"
    dial_ticks               "#aaa594"
    dial_thumb               "#9c5fbf"
    dial_thumb_highlight     "#cf8ef2"
    dial_active              "#cf8ef2"
    dial_label               "#939e53"
    tooltip_fill             "#F7F6F2"
    tooltip_border           "#E0DCCC"
    tooltip_text             "#081621"
    dial_iolet               "#AAAAAA"
    dial_iolet_border        "#AAAAAA"

    gop_box 		         "#AB6526"

    atom_box_label 	 	     "#939e53"
    comment 		         "#AAAAAA"

    obj_box_outline 	     "#DCD6C5"
    msg_box_outline 	     "#DCD6C5"
    atom_box_outline 	     "#DCD6C5"
    msg_box_fill 		     "#DCD6C5"
    obj_box_fill 		     "#DCD6C5"
    atom_box_fill 		     "#DCD6C5"
    atom_box_focus_outline   "#AE7CCB"

    obj_box_text 		     "#5F5F5E"
    msg_box_text 		     "#5F5F5E"
    atom_box_text 		     "#5F5F5E"
    pdwindow_post_text 	     "#5F5F5E"
    helpbrowser_text 	     "#5F5F5E"
    text_window_text 	     "#5F5F5E"

    signal_cord 		     "#869438"
    signal_iolet 		     "#869438"
    signal_iolet_border      "#869438"
    msg_cord 		         "#AAAAAA"
    msg_iolet 		         "#AAAAAA"
    msg_iolet_border         "#AAAAAA"

    graph_outline 		     "#5F5F5E"
    graph_text 		         "#5F5F5E"
    array_name 		         "#5F5F5E"
    array_values 		     "#9C5FBF"

    canvas_fill 		     "#F3F1EB"
    pdwindow_fill 		     "#F3F1EB"
    text_window_fill 	     "#F3F1EB"
    helpbrowser_fill 	     "#F3F1EB"

    obj_box_outline_broken   "#FF4747"
    pdwindow_fatal_text 	 "#FF4747"
    pdwindow_error_text 	 "#FF4747"
    pdwindow_fatal_highlight "#F3F1EB" ;# this is the same as background (so no highlight)
    pdwindow_debug_text 	 "#205988"

    helpbrowser_highlight 	 "#c2baa1"
    selection_rectangle      "#9C5FBF"
    selected 		         "#AE7CCB"
    txt_highlight_front      "#AE7CCB"
    text_window_highlight    "#AAAAAA"
    txt_highlight 		     "#AAAAAA"

    text_window_cursor 	     "#2B2B2B"
    canvas_text_cursor 	     "#2B2B2B"
    cursor                   "#2B2B2B"

    scrollbox_fill           "#DCD6C5"
    text                     "#5F5F5E"
}

# gruvbox
# commented out bc of my implementation, should fix in the future
# array set ::darkTheme {
#    gop_box 		         "#b85651"

#     canvas_fill 		     "#32302f"
#     pdwindow_fill 		 "#32302f"
#     helpbrowser_fill 	     "#32302f"
#     text_window_fill 	     "#32302f"

#     obj_box_text 		     "#a9b665"
#     msg_box_text 		     "#a9b665"
#     atom_box_text 		 "#a9b665"
#     pdwindow_post_text 	 "#c5b18d"
#     atom_box_label 	 	 "#c5b18d"
#     helpbrowser_text 	     "#c5b18d"
#     text_window_text 	     "#c5b18d"
#     comment 		         "#928374"

#     obj_box_outline 	     "#5a524c"
#     msg_box_outline 	     "#5a524c"
#     atom_box_outline 	     "#5a524c"
#     msg_box_fill 		     "#5a524c"
#     obj_box_fill 		     "#5a524c"
#     atom_box_fill 		 "#5a524c"

#     signal_cord 		     "#c18f41"
#     signal_iolet 		     "#c18f41"
#     signal_iolet_border    "#c18f41"
#     msg_cord 		         "#a89984"
#     msg_iolet 		     "#a89984"
#     msg_iolet_border       "#a89984"

#     graph_outline 		     "#5a524c"
#     graph_text 		         "#a9b665"
#     array_name 		         "#a9b665"
#     array_values 		     "#d3869b"

#     obj_box_outline_broken   "#ea6962"
#     pdwindow_fatal_text 	 "#ea6962"
#     pdwindow_fatal_highlight "#32302f"
#     pdwindow_error_text 	 "#ea6962"
#     pdwindow_debug_text 	 "#8f9a52"

#     selected 		         "#7daea3"
#     selection_rectangle      "#7daea3"
#     helpbrowser_highlight 	 "#7c6f64"
#     txt_highlight_front      "#7daea3"
#     text_window_highlight    "#7c6f64"
#     txt_highlight 		     "#7c6f64"

#     text_window_cursor 	     "#FFFFFF"
#     canvas_text_cursor 	     "#FFFFFF"
#     cursor                   "#FFFFFF"

#     scrollbox_fill           "#45403d"
#     text                     "#ddc7a1"
# }

# primary a1d044, light d5ff76, dark 6f9f03
# primary 403f34, light 6b6a5e, dark 1a190d

# monokai
# array set ::darkTheme {
#     dial_background          "#403f34"
#     dial_track               "#6b6a5e"
#     dial_ticks               "#A9A89E"
#     dial_thumb               "#6f9f03"
#     dial_thumb_highlight     "#a1d044"
#     dial_active              "#a1d044"
#     dial_label               "#88846f"
#     tooltip_fill             "#56564D"
#     tooltip_border           "#6C6C60"
#     tooltip_text             "#E7E2B1"
#     dial_iolet               "#A3A28F"
#     dial_iolet_border        "#A3A28F"

#     gop_box 		         "#D8447A"

#     canvas_fill 		     "#272822"
#     pdwindow_fill 		     "#272822"
#     scrollbox_fill           "#272822"
#     helpbrowser_fill 	     "#272822"
#     text_window_fill 	     "#272822"

#     obj_box_text 		     "#A1D044"
#     msg_box_text 		     "#D6CC78"
#     atom_box_text 		     "#AE81FF"
#     atom_box_label 	 	     "#88846f"
#     pdwindow_post_text 	     "#CFCFCF"
#     helpbrowser_text 	     "#CFCFCF"
#     text_window_text 	     "#CFCFCF"
#     text                     "#CFCFCF"
#     comment 		         "#88846f"

#     obj_box_outline 	     "#403f34"
#     msg_box_outline 	     "#403f34"
#     atom_box_outline 	     "#403f34"
#     atom_box_focus_outline   "#90BFC9"
#     msg_box_fill 		     "#403f34"
#     obj_box_fill 		     "#403f34"
#     atom_box_fill 		     "#403f34"

#     signal_cord 		     "#D99A53"
#     signal_iolet 		     "#D99A53"
#     signal_iolet_border      "#D99A53"
#     msg_cord 		         "#A3A28F"
#     msg_iolet 		         "#A3A28F"
#     msg_iolet_border         "#A3A28F"

#     graph_outline 		     "#403f34"
#     graph_text 		         "#88846f"
#     array_name 		         "#AE81FF"
#     array_values 		     "#AE81FF"

#     obj_box_outline_broken   "#DC5E5E"
#     pdwindow_fatal_text 	 "#DC5E5E"
#     pdwindow_error_text 	 "#DC5E5E"
#     pdwindow_fatal_highlight "#272822"
#     pdwindow_debug_text 	 "#A1D044"

#     selected 		         "#90BFC9"
#     selection_rectangle      "#90BFC9"
#     helpbrowser_highlight 	 "#716F5B"
#     txt_highlight_front      "#060901"
#     text_window_highlight    "#90BFC9"
#     txt_highlight 		     "#716F5B"

#     text_window_cursor 	     "#FFFFFF"
#     canvas_text_cursor 	     "#FFFFFF"
#     cursor                   "#FFFFFF"
# }

# One Dark Pro
array set ::darkTheme {
    # dial_background          "#403f34"
    # dial_track               "#6b6a5e"
    # dial_ticks               "#A9A89E"
    # dial_thumb               "#6f9f03"
    # dial_thumb_highlight     "#a1d044"
    # dial_active              "#a1d044"
    # dial_label               "#88846f"
    # tooltip_fill             "#56564D"
    # tooltip_border           "#6C6C60"
    # tooltip_text             "#E7E2B1"
    # dial_iolet               "#A3A28F"
    # dial_iolet_border        "#A3A28F"

    gop_box 		         "#dddddd"

    canvas_fill 		     "#282C34"
    pdwindow_fill 		     "#282C34"
    scrollbox_fill           "#282C34"
    helpbrowser_fill 	     "#282C34"
    text_window_fill 	     "#282C34"

    obj_box_text 		     "#98C379"
    msg_box_text 		     "#61AFEF"
    atom_box_text 		     "#D19A66"
    atom_box_label 	 	     "#7F848E"
    pdwindow_post_text 	     "#ABB2BF"
    helpbrowser_text 	     "#ABB2BF"
    text_window_text 	     "#ABB2BF"
    text                     "#ABB2BF"
    comment 		         "#7F848E"

    obj_box_outline 	     "#474E5C"
    msg_box_outline 	     "#474E5C"
    atom_box_outline 	     "#474E5C"
    atom_box_focus_outline   "#dddddd"
    msg_box_fill 		     "#474E5C"
    obj_box_fill 		     "#474E5C"
    atom_box_fill 		     "#474E5C"

    signal_cord 		     "#E4C386"
    signal_iolet 		     "#E4C386"
    signal_iolet_border      "#E4C386"
    msg_cord 		         "#ABB2BF"
    msg_iolet 		         "#ABB2BF"
    msg_iolet_border         "#ABB2BF"

    graph_outline 		     "#7F848E"
    graph_text 		         "#7F848E"
    array_name 		         "#7F848E"
    array_values 		     "#D19A66"

    obj_box_outline_broken   "#F44747"
    pdwindow_fatal_text 	 "#F44747"
    pdwindow_error_text 	 "#F44747"
    pdwindow_fatal_highlight "#282C34"
    pdwindow_debug_text 	 "#c678dd"

    selected 		         "#dddddd"
    selection_rectangle      "#dddddd"
    helpbrowser_highlight 	 "#677696"
    helpbrowser_hl_text      "#ABB2BF"
    txt_highlight_front      "#ABB2BF"
    text_window_hl_text      "#ABB2BF"
    text_window_highlight    "#677696"
    txt_highlight 		     "#677696"

    text_window_cursor 	     "#528BFF"
    canvas_text_cursor 	     "#528BFF"
    cursor                   "#528BFF"
}