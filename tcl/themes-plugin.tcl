namespace eval color-themes {
    variable current_name
    variable current_theme
    variable hover_theme
    variable selected_theme
    variable num_themes
    variable canvas_height
}

# found https://comp.lang.tcl.narkive.com/39ezTJaO/string-trimright-bug
proc ::color-themes::trimsubstringright {str substr} {
    set l [expr {[string length $substr]-1}]
    if {[string range $str end-$l end] == $substr} {
        incr l
        return [string range $str 0 end-$l]
    } else {
        return -code error "$str does not end in $substr"
    }
}

proc ::color-themes::reset_defaults {} {
    array set ::pd_colors {
        gop_box 		         "#AB6526"

        atom_box_label 	 	     "#939e53"
        comment 		         "#AAAAAA"

        obj_box_outline 	     "#DCD6C5"
        msg_box_outline 	     "#DCD6C5"
        atom_box_outline 	     "#DCD6C5"
        atom_box_focus_outline   "#AE7CCB"
        msg_box_fill 		     "#DCD6C5"
        obj_box_fill 		     "#DCD6C5"
        atom_box_fill 		     "#DCD6C5"

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
        pdwindow_fatal_highlight "#F3F1EB"
        pdwindow_debug_text 	 "#205988"

        helpbrowser_highlight 	 "#c2baa1"
        helpbrowser_hl_text      "#AE7CCB"
        selection_rectangle      "#9C5FBF"
        selected 		         "#AE7CCB"
        txt_highlight_front      "#AE7CCB"
        text_window_highlight    "#AAAAAA"
        text_window_hl_text      "#AE7CCB"
        txt_highlight 		     "#AAAAAA"

        text_window_cursor 	     "#2B2B2B"
        canvas_text_cursor 	     "#2B2B2B"
        cursor                   "#2B2B2B"

        scrollbox_fill           "#DCD6C5"
        text                     "#5F5F5E"
    }
}

proc ::color-themes::set_theme {name} {
    ::pdwindow::post "attempting to set theme to $name\n"
    variable current_name
    variable current_theme
    # check for theme
    if { ![file exists $::sys_guidir/themes/$name-plugin.tcl] } {
        ::pdwindow::error "no theme '$name-plugin.tcl'\n"
        return
    }
    #store name
    set current_name $name
    #reset defaults
    ::color-themes::reset_defaults
    #load theme
    source $::sys_guidir/themes/${name}-plugin.tcl
    # redraw everything
    foreach wind [wm stackorder .] {
        if {[winfo class $wind] eq "PatchWindow"} {
            ::pdwindow::post "we are a PatchWindow\n"
            pdsend "$wind map 0"
            pdsend "$wind map 1"
            set tmpcol [::pdtk_canvas::get_color txt_highlight $wind]
            if {$tmpcol ne ""} {
                ${wind}.c configure -selectbackground $tmpcol
            }
            set tmpcol [::pdtk_canvas::get_color canvas_fill $wind]
            if {$tmpcol ne ""} {
                ::pdwindow::post "canvas_fill color is $tmpcol\n"
                ${wind}.c configure -background $tmpcol
            }
            set tmpcol [::pdtk_canvas::get_color canvas_text_cursor $wind]
            if {$tmpcol ne ""} {
                ${wind}.c configure -insertbackground $tmpcol
            }
            #in Tk 8.6 the selectforeground is set by the os theme?
            set tmpcol [::pdtk_canvas::get_color txt_highlight_front $wind]
            if {$tmpcol ne ""} {
                ${wind}.c configure -selectforeground $tmpcol
            }
        } elseif {[winfo class $wind] eq "HelpBrowser"} {
            foreach child [winfo children .helpbrowser.c.f] {
                if {[winfo class $child] eq "Listbox"} {
                    ::helpbrowser::set_listbox_colors $child
                }
            }
        } else {
            # assume text window if text widget
            if {[winfo exists $wind.text]} {
                set tmpcol [::pdtk_canvas::get_color text_window_text $wind]
                if {$tmpcol ne ""} {
                    $wind.text configure -foreground $tmpcol
                }
                set tmpcol [::pdtk_canvas::get_color text_window_cursor $wind]
                if {$tmpcol ne ""} {
                    $wind.text configure -insertbackground $tmpcol
                }
                set tmpcol [::pdtk_canvas::get_color text_window_fill $wind]
                if {$tmpcol ne ""} {
                    $wind.text configure -background $tmpcol
                }
                set tmpcol [::pdtk_canvas::get_color text_window_highlight $wind]
                if {$tmpcol ne ""} {
                    $wind.text configure -selectbackground $tmpcol
                }
                set tmpcol [::pdtk_canvas::get_color text_window_hl_text $wind]
                if {$tmpcol ne ""} {
                    $wind.text configure -selectforeground $tmpcol
                }
            }
        }
    }
    ::pdwindow::set_colors
}

proc ::color-themes::make_default {} {
    variable current_name
    if {[catch {set fp [open $::sys_guidir/current-theme.txt w]}]} {
        ::pdwindow::error "couldn't open file for writing\n"
        return
    }
    puts -nonewline $fp $current_name
    close $fp
    ::pdwindow::post "saved $current_name as the theme\n"
}

proc ::color-themes::print {} {
    ::pdwindow::post "color themes in $::sys_guidir/themes:\n"
    foreach theme [lsort [glob -path $::sys_guidir/themes/ *-plugin.tcl]] {
        ::pdwindow::post "[{::color-themes::trimsubstringright} [file tail $theme] -plugin.tcl]\n"
    }
}

proc ::color-themes::motion {box} {
    #::pdwindow::post "box: $box\n"
    if {$box ne ${::color-themes::hover_theme}} {
        if {${::color-themes::hover_theme} ne "" && \
        ${::color-themes::hover_theme} ne \
        ${::color-themes::selected_theme} } {
            $::ctdf.theme_list.c.f${::color-themes::hover_theme}.c \
                itemconfigure box${::color-themes::hover_theme} -outline \
                black -width 1
            $::ctdf.theme_list.c \
                itemconfigure box${::color-themes::hover_theme} -outline \
                black -width 1
        }
        if {$box ne ${::color-themes::selected_theme}} {
            $::ctdf.theme_list.c.f$box.c itemconfigure \
                box$box -outline [::pdtk_canvas::get_color selected .colortheme_dialog] -width 7
            $::ctdf.theme_list.c itemconfigure \
                box$box -outline [::pdtk_canvas::get_color selected .colortheme_dialog] -width 7
        }
        set {::color-themes::hover_theme} $box
    }
}

proc ::color-themes::click {box} {
    if {${::color-themes::selected_theme} ne "" && \
    ${::color-themes::selected_theme} ne $box} {
        $::ctdf.theme_list.c.f${::color-themes::selected_theme}.c \
            itemconfigure box${::color-themes::selected_theme} -outline \
            black -width 1
        $::ctdf.theme_list.c \
            itemconfigure box${::color-themes::selected_theme} -outline \
            black -width 1
    }
    set {::color-themes::hover_theme} $box
    set {::color-themes::selected_theme} $box

    $::ctdf.theme_list.c.f$box.c itemconfigure \
        box${::color-themes::hover_theme} -outline \
        [::pdtk_canvas::get_color gop_box .colortheme_dialog] -width 7
    $::ctdf.theme_list.c itemconfigure \
        box${::color-themes::hover_theme} -outline \
        [::pdtk_canvas::get_color gop_box .colortheme_dialog] -width 7
}

proc ::color-themes::scroll {box coord units boxincr} {
    variable num_themes
    # not sure of a better way to simulate hovering..
    set ocanvy [$::ctdf.theme_list.c canvasy 0]
    $::ctdf.theme_list.c yview scroll [expr {- ($units)}] units
    {::color-themes::motion} [expr max(0, min($box + int($coord + \
        [$::ctdf.theme_list.c canvasy 0] - $ocanvy)/$boxincr, \
        $num_themes-1))]
}

proc ::color-themes::apply {names} {
    variable selected_theme
    if {$selected_theme eq ""} {
        return
    }
    ::color-themes::set_theme [lindex $names $selected_theme]
}

proc ::color-themes::save_dark {names} {
    variable selected_theme
    if {$selected_theme eq ""} {return}
    set name [lindex $names $selected_theme]
    if {[catch {set fp [open $::sys_guidir/dark-theme.txt w]}]} {
        ::pdwindow::error "couldn't open file for writing\n"
        return
    }
    puts -nonewline $fp $name
    close $fp
    ::pdwindow::post "saved $name as the dark theme\n"
}

proc ::color-themes::delete_dark {} {
    if {[catch [file delete $::sys_guidir/dark-theme.txt]]} {
        ::pdwindow::error "couldn't delete dark theme file\n"
        return
    }
    ::pdwindow::post "deleted dark-theme.txt\n"
}

proc ::color-themes::opendialog {} {
    variable current_name
    variable hover_theme
    variable selected_theme
    variable num_themes
    variable canvas_height
    set hover_theme ""
    set selected_theme ""
    # save current theme
    array set temp_theme [array get ::pd_colors]
    if {[winfo exists .colortheme_dialog]} {
        wm deiconify .colortheme_dialog
        raise .colortheme_dialog
        focus .colortheme_dialog
        return
    }

    toplevel .colortheme_dialog -class ColorThemeDialog
    wm title .colortheme_dialog [_ "Themes"]
    wm group .colortheme_dialog .
    wm resizable .colortheme_dialog 0 1
    wm transient .colortheme_dialog
    wm minsize .colortheme_dialog 400 300
    if {$::windowingsystem eq "aqua"} {
        .colortheme_dialog configure -menu $::dialog_menubar
    }
    set themes [lsort [glob -path $::sys_guidir/themes/ *-plugin.tcl]]

    ttk::frame .colortheme_dialog.frame -padding 5
    set ::ctdf .colortheme_dialog.frame

    ttk::frame     $::ctdf.theme_list -padding 5
    ttk::scrollbar $::ctdf.theme_list.sy -command "$::ctdf.theme_list.c yview"
    canvas         $::ctdf.theme_list.c -yscrollcommand \
                   "$::ctdf.theme_list.sy set" -width 400

    grid $::ctdf -row 0 -column 0 -sticky nwes
    grid $::ctdf.theme_list -row 0 -column 0 -sticky nwes
    grid $::ctdf.theme_list.c -sticky ns -row 0 -column 0 -padx 5 -pady 2 -ipady 20;#ipadx 20
    grid $::ctdf.theme_list.sy -sticky ns -row 0 -column 1
    grid rowconfigure .colortheme_dialog 0 -weight 1 ;#makes sure that $::ctdf expands to fill window
    grid rowconfigure $::ctdf 0 -weight 1
    grid rowconfigure $::ctdf 1 -weight 1
    grid rowconfigure $::ctdf.theme_list 0 -weight 1

    set height 5
    set fontinfo [list $::font_family -14 $::font_weight]
    set mwidth [font measure $fontinfo M]
    set mheight [expr {[font metrics $fontinfo -linespace] + 5}]
    set boxheight [expr {$mheight * 4 + 12}] ;# height of theme demo
    set boxincr [expr {$boxheight + 5}]
    set corner [expr {$mheight/4}]
    set counter 0
    set names ""

    foreach i $themes {
        ::color-themes::reset_defaults
        source ${i}
        set name [{::color-themes::trimsubstringright} [file tail ${i}] -plugin.tcl]
        lappend names $name
        # canvas for txt_highlight
        ttk::labelframe $::ctdf.theme_list.c.f$counter -text " ${name} " -padding "2 1"

        # $::ctdf.theme_list.c create rectangle  0 $height 400 \
        #     [expr {$height + $boxheight}] -outline black -width 1 -tags \
        #     box$counter

        # this puts the labelframe in the canvas
        $::ctdf.theme_list.c create window 0 $height -window \
            $::ctdf.theme_list.c.f$counter -anchor nw -width \
            400 -height $boxheight

        # then we put a canvas in that window
        # this canvas draws the example theme
        canvas $::ctdf.theme_list.c.f$counter.c -width 392 -height \
            [expr $boxheight-20] -background $::pd_colors(canvas_fill) \
            -highlightthickness 0

        grid $::ctdf.theme_list.c.f$counter.c
        bind $::ctdf.theme_list.c.f$counter.c <MouseWheel> \
            [list {::color-themes::scroll} $counter %y %D $boxincr]
        bind $::ctdf.theme_list.c.f$counter.c <Motion> \
            [list {::color-themes::motion} $counter]
        bind $::ctdf.theme_list.c.f$counter.c <ButtonPress> \
            [list {::color-themes::click} $counter]

        # theme demo outline
        # $::ctdf.theme_list.c.f$counter.c create rectangle 0 0 \
        #     400 $boxheight -outline black -width 1 -tags box$counter

        # name
        # set twidth [expr {$mwidth * [string length $name] + 4}]
        # $::ctdf.theme_list.c.f$counter.c create rectangle 2 0 \
        #     [expr {2 + $twidth}] [expr {$mheight}] -fill black
        # $::ctdf.theme_list.c.f$counter.c create text 4 3 \
        #     -text ${name} -anchor nw -font $fontinfo -fill white

        # (signal) object box
        set twidth [expr {$mwidth * 13 + 4}]
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            3 5 \
            [expr {$twidth + 5}] [expr {$mheight+5}] \
            -fill $::pd_colors(obj_box_fill) -outline $::pd_colors(obj_box_outline)
        # (signal) object text
        $::ctdf.theme_list.c.f$counter.c create text 5 8\
            -text signal_object -anchor nw \
            -font $fontinfo -fill $::pd_colors(obj_box_text)
        # signal outlet
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            3 [expr {$mheight+1}] \
            16 [expr {$mheight+5}] \
            -fill $::pd_colors(signal_iolet) -outline \
            $::pd_colors(signal_iolet_border)
        # signal cable
        $::ctdf.theme_list.c.f$counter.c create line \
            8 [expr {$mheight+5}] \
            8 $boxheight \
            -fill $::pd_colors(signal_cord) -width 3
        # broken object
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            [expr {$twidth + 9}] 5 \
            [expr {$twidth*2 + 11}] [expr {$mheight+5}] \
            -fill $::pd_colors(obj_box_fill) \
            -outline $::pd_colors(obj_box_outline_broken) -dash -
        # broken object text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$twidth + 11}] 9 \
            -text broken_object -anchor nw \
            -font $fontinfo -fill $::pd_colors(obj_box_text)
        # message box
        set twidth [expr {$mwidth * 11 + 4}]
        set tempy [expr {$mheight+10}]
        set tempx [expr {$twidth + 16}]
        $::ctdf.theme_list.c.f$counter.c create polygon \
            14 $tempy \
            [expr {$tempx + $corner}] $tempy \
            $tempx [expr {$tempy + $corner}] \
            $tempx [expr {$tempy + $mheight - $corner}] \
            [expr {$tempx + $corner}] [expr {$tempy + $mheight}] \
            14 [expr {$tempy + $mheight}] \
            -fill $::pd_colors(msg_box_fill) -outline $::pd_colors(msg_box_outline)
        # message box text
        $::ctdf.theme_list.c.f$counter.c create text \
            17 [expr {$mheight+13}] \
            -text message_box -anchor nw \
            -font $fontinfo -fill $::pd_colors(msg_box_text)
        # message outlet
        set tempy [expr {$tempy + $mheight}]
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            14 [expr {$tempy - 3}] \
            25 $tempy \
            -fill $::pd_colors(msg_iolet) \
            -outline $::pd_colors(msg_iolet_border)
        # message cable
        $::ctdf.theme_list.c.f$counter.c create line \
            20 $tempy \
            20 [expr {$boxheight + $height}] \
            -fill $::pd_colors(msg_cord) -width 2
        # atom box label
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 8}] [expr {$mheight+13}] \
            -text label -anchor nw -font $fontinfo \
            -fill $::pd_colors(atom_box_label)
        # atom box
        set twidth [expr {$mwidth * 5 + 4}]
        set tempx [expr {$tempx + $twidth + 7}]
        set tempy [expr {$mheight+10}]
        $::ctdf.theme_list.c.f$counter.c create polygon \
            $tempx $tempy \
            [expr {$tempx + $twidth - $corner}] $tempy \
            [expr {$tempx + $twidth}] [expr {$tempy + $corner}] \
            [expr {$tempx + $twidth}] [expr {$tempy + $mheight}] \
            $tempx [expr {$tempy + $mheight}] \
            -fill $::pd_colors(atom_box_fill) \
            -outline $::pd_colors(atom_box_outline)
        # atom box text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 2}] [expr {$tempy + 3}] -text gatom -anchor nw \
            -font $fontinfo -fill $::pd_colors(atom_box_text)
        incr tempx [expr {$twidth + 15}]
        set twidth [expr {$mwidth * 8 + 4}]
        # selected box
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            $tempx $tempy [expr {$tempx + $twidth}] \
            [expr {$tempy + $mheight}] -fill $::pd_colors(obj_box_fill) \
            -outline $::pd_colors(selected)
        # selected box text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 2}] [expr {$tempy + 3}] -text selected -anchor nw \
            -font $fontinfo -fill $::pd_colors(selected)
        # selection "lasso"
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            [expr {$tempx - 6}] [expr {$tempy + 10}] \
            [expr {$tempx + $twidth*0.8}] [expr {$tempy + $mheight + 6}] \
            -outline $::pd_colors(selection_rectangle)
        # comment
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$mwidth * 15}] [expr {$mheight + 35}] -text comment \
            -anchor nw -font $fontinfo -fill $::pd_colors(comment)
        # array
        incr tempx [expr {$twidth + 6}]
        set tempy [expr {$mheight*3 + 12}]
        set twidth [expr {$mwidth * 5 + 4}]
        $::ctdf.theme_list.c.f$counter.c create text \
            $tempx 9 -text array \
            -anchor nw -font $fontinfo -fill $::pd_colors(array_name)
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            $tempx [expr {$mheight + 5}] [expr {$tempx + $twidth}] \
            $tempy -outline $::pd_colors(graph_outline)
        set tempy [expr {2*$mheight + 9}]
        $::ctdf.theme_list.c.f$counter.c create line \
            $tempx $tempy [expr {$tempx + $twidth}] \
            $tempy -fill $::pd_colors(array_values) -width 2
        # pd window/console
        incr tempx [expr {$twidth + 5}]
        # console fill
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            $tempx 0 [expr {$tempx + $twidth}] \
            $boxheight -fill $::pd_colors(pdwindow_fill)
        # debug text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 2}] 3 -text debug \
            -anchor nw -font $fontinfo -fill $::pd_colors(pdwindow_debug_text)
        set tempy [expr {$mheight - 1}]
        # post text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 2}] $tempy -text post \
            -anchor nw -font $fontinfo -fill $::pd_colors(pdwindow_post_text)
        incr tempy [expr {$mheight - 4}]
        # error text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 2}] $tempy -text error \
            -anchor nw -font $fontinfo -fill $::pd_colors(pdwindow_error_text)
        incr tempy [expr {$mheight - 4}]
        # fatal text highlight
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            [expr {$tempx + 1}] $tempy [expr {$tempx + $twidth - 1}] \
            [expr {$tempy + $mheight - 4}] -fill \
            $::pd_colors(pdwindow_fatal_highlight) -outline \
            $::pd_colors(pdwindow_fatal_highlight)
        # fatal text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 2}] $tempy -text fatal \
            -anchor nw -font $fontinfo -fill $::pd_colors(pdwindow_fatal_text)
        # go back and make GOP
        set tempx [expr {$mwidth * 26 + 30}]
        set tempy [expr {3+$mheight}]
        # gop box
        $::ctdf.theme_list.c.f$counter.c create rectangle \
            $tempx 5 [expr {$tempx + $twidth}] \
            $tempy -outline $::pd_colors(graph_outline)
        # gop text
        $::ctdf.theme_list.c.f$counter.c create text \
            [expr {$tempx + 2}] 8 -text GOP \
            -anchor nw -font $fontinfo -fill $::pd_colors(graph_text)
        incr height $boxincr
        incr counter
    }

    set canvas_height $height
    set num_themes $counter

    $::ctdf.theme_list.c configure -scrollregion [list 0 0 400 $height]

    # create and grid the buttons
    ttk::frame $::ctdf.button_frame
    ttk::button $::ctdf.button_frame.apply -text [_ "Apply"] \
         -command [list {::color-themes::apply} $names] -width 5
    ttk::button $::ctdf.button_frame.close -text [_ "Close"] \
         -command "destroy $::ctdf" -width 5
    ttk::button $::ctdf.button_frame.save -text [_ "Save Current"] \
        -command {::color-themes::make_default} -width 12

    grid $::ctdf.button_frame -row 1 -column 0 -padx 8 -sticky ws
    grid $::ctdf.button_frame.apply -row 0 -column 0
    grid $::ctdf.button_frame.close -row 0 -column 1
    grid $::ctdf.button_frame.save -row 0 -column 2
    grid rowconfigure $::ctdf.button_frame 0 -weight 1
    grid rowconfigure $::ctdf.button_frame 1 -weight 1

    if {$::windowingsystem eq "aqua"} {
        ttk::frame $::ctdf.button_frame.darkmode_buttons
        ttk::button $::ctdf.button_frame.darkmode_buttons.dark -text [_ "Save as Dark Theme"] \
            -command [list {::color-themes::save_dark} $names] -width 14
        ttk::button $::ctdf.button_frame.darkmode_buttons.undark -text [_ "Delete Dark Theme"] \
            -command {::color-themes::delete_dark} -width 13
        grid $::ctdf.button_frame.darkmode_buttons -row 1 -column 0 -columnspan 3 -sticky ws -pady 2
        grid $::ctdf.button_frame.darkmode_buttons.dark -row 0 -column 0
        grid $::ctdf.button_frame.darkmode_buttons.undark -row 0 -column 1
    } else {
        grid configure $::ctdf.button_frame.apply -pady 5
        grid configure $::ctdf.button_frame.close -pady 5
        grid configure $::ctdf.button_frame.save -pady 5
    }
    bind $::ctdf.theme_list.c <MouseWheel> {
        $::ctdf.theme_list.c yview scroll [expr {- (%D)}] units
    }

    bind $::ctdf.theme_list.c <Leave> {
        if {${::color-themes::hover_theme} ne "" && \
        ${::color-themes::selected_theme} ne ${::color-themes::hover_theme}} {
            $::ctdf.theme_list.c.f${::color-themes::hover_theme}.c \
                itemconfigure box${::color-themes::hover_theme} -outline \
                black -width 1
            $::ctdf.theme_list.c \
                itemconfigure box${::color-themes::hover_theme} -outline \
                black -width 1
        }
        set {::color-themes::hover_theme} ""
    }
    array set ::pd_colors [array get temp_theme]
}

proc ::color-themes::init {mymenu} {
    set ::color-themes::this_path $::current_plugin_loadpath
    #::pdwindow::post "menu: $mymenu\n"
    $mymenu add command -label [_ "Themes..."] \
        -command {::color-themes::opendialog}
    if {[catch {set darkmode [exec defaults read -g AppleInterfaceStyle]}]} {
        set darkmode ""
    }
    if {$::windowingsystem eq "aqua" && $darkmode eq "Dark" && [file exists \
        $::current_plugin_loadpath/dark-theme.txt] } {
        if {![catch {set fp [open $::current_plugin_loadpath/dark-theme.txt r]}]} {
        # not sure if the console is ready..
            ::color-themes::set_theme [read -nonewline $fp]
            close $fp
        }
        return
    }
    if {[catch {set fp [open $::current_plugin_loadpath/current-theme.txt r]}]} {
        return
    }
    ::color-themes::set_theme [read -nonewline $fp]
    close $fp
}

# for some reason returning from source didn't work
if {![array exists ::pd_colors]} {
    ::pdwindow::post "color-themes: no ::pd_colors array: skipping\n"
    # return not working here
} else {
    if {$::windowingsystem eq "aqua"} {
        ::color-themes::init .menubar.apple.preferences
    } else {
        ::color-themes::init .menubar.file.preferences
    }
}