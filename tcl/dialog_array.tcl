package provide dialog_array 0.1

namespace eval ::dialog_array:: {
    namespace export pdtk_array_dialog
    namespace export pdtk_array_listview_new
    namespace export pdtk_array_listview_fillpage
    namespace export pdtk_array_listview_setpage
    namespace export pdtk_array_listview_closeWindow
}

# global variables for the listview
array set pd_array_listview_entry {}
array set pd_array_listview_id {}
array set pd_array_listview_page {}
set pd_array_listview_pagesize 0
# this stores the state of the "save me" check button
array set saveme_button {}
# this stores the state of the "draw as" radio buttons
array set drawas_button {}
# this stores the state of the "in new graph"/"in last graph" radio buttons
# and the "delete array" checkbutton
# I've removed the delete array option, but the code for it is still there
array set otherflag_button {}

############ pdtk_array_dialog -- dialog window for arrays #########

proc ::dialog_array::pdtk_array_listview_setpage {arrayName page} {
    set ::pd_array_listview_page($arrayName) $page
}

proc ::dialog_array::listview_changepage {arrayName np} {
    pdtk_array_listview_setpage \
        $arrayName [expr $::pd_array_listview_page($arrayName) + $np]
    pdtk_array_listview_fillpage $arrayName
}

proc ::dialog_array::pdtk_array_listview_fillpage {arrayName} {
    set windowName [format ".%sArrayWindow" $arrayName]
    set topItem [expr [lindex [$windowName.lb yview] 0] * \
                     [$windowName.lb size]]

    if {[winfo exists $windowName]} {
        set cmd "$::pd_array_listview_id($arrayName) \
               arrayviewlistfillpage \
               $::pd_array_listview_page($arrayName) \
               $topItem"

        pdsend $cmd
    }
}

proc ::dialog_array::pdtk_array_listview_new {id arrayName page} {
    set ::pd_array_listview_page($arrayName) $page
    set ::pd_array_listview_id($arrayName) $id
    set windowName [format ".%sArrayWindow" $arrayName]
    if [winfo exists $windowName] then [destroy $windowName]
    toplevel $windowName
    wm group $windowName .
    wm protocol $windowName WM_DELETE_WINDOW \
        "::dialog_array::listview_close $id $arrayName"
    wm title $windowName [concat $arrayName "(list view)"]

#Theme and style
    ttk::style configure s.TButton -background "#32302f" -foreground "#c5b18d"
    ttk::style map s.TButton -foreground [list hover "#292828"]
    ttk::style configure s.TFrame -background "#383432"

# Widgets & Layout
    # FIXME
    set font 12
    tk::listbox $windowName.lb -height 20 -width 25\
                            -selectmode extended \
                            -relief solid -background white -borderwidth 1 \
                            -font [format {{%s} %d %s} $::font_family $font $::font_weight]\
                            -yscrollcommand "$windowName.lb.sb set" \
                            -background "#3c3836" -foreground "#c5b18d" \
                            -selectbackground "#7c6f64" -selectforeground "#7daea3"

    ttk::scrollbar $windowName.lb.sb -command "$windowName.lb yview" -orient vertical
    place configure $windowName.lb.sb -relheight 1 -relx 0.9 -relwidth 0.1

    bind $windowName.lb <Double-ButtonPress-1> \
        "::dialog_array::listview_edit $arrayName $page $font"
    # handle copy/paste
    switch -- $::windowingsystem {
        "x11" {selection handle $windowName.lb \
                   "::dialog_array::listview_lbselection $arrayName"}
        "win32" {bind $windowName.lb <ButtonPress-3> \
                     "::dialog_array::listview_popup $arrayName"}
    }
    ttk::frame $windowName.buttons 
    ttk::frame $windowName.buttons.pad -width 27 
    ttk::button $windowName.buttons.prevBtn -text "prev" -width -1  \
                               -command "::dialog_array::listview_changepage $arrayName -1"
    ttk::button $windowName.buttons.nextBtn -text "next" -width -1  \
                               -command "::dialog_array::listview_changepage $arrayName 1"
# Layout
    grid $windowName.lb -column 0 -row 0
    grid $windowName.buttons -column 0 -row 1 -sticky nwes
    grid $windowName.buttons.pad -column 0 -row 0
    grid $windowName.buttons.prevBtn -column 1 -row 0 -pady 2
    grid $windowName.buttons.nextBtn -column 2 -row 0

    focus $windowName
}

proc ::dialog_array::listview_lbselection {arrayName off size} {
    set windowName [format ".%sArrayWindow" $arrayName]
    set itemNums [$windowName.lb curselection]
    set cbString ""
    for {set i 0} {$i < [expr [llength $itemNums] - 1]} {incr i} {
        set listItem [$windowName.lb get [lindex $itemNums $i]]
        append cbString [string range $listItem \
                             [expr [string first ") " $listItem] + 2] \
                             end]
        append cbString "\n"
    }
    set listItem [$windowName.lb get [lindex $itemNums $i]]
    append cbString [string range $listItem \
                         [expr [string first ") " $listItem] + 2] \
                         end]
    set last $cbString
}

# Win32 uses a popup menu for copy/paste
proc ::dialog_array::listview_popup {arrayName} {
    set windowName [format ".%sArrayWindow" $arrayName]
    if [winfo exists $windowName.popup] then [destroy $windowName.popup]
    menu $windowName.popup -tearoff false
    $windowName.popup add command -label [_ "Copy"] \
        -command "::dialog_array::listview_copy $arrayName; \
                  destroy $windowName.popup"
    $windowName.popup add command -label [_ "Paste"] \
        -command "::dialog_array::listview_paste $arrayName; \
                  destroy $windowName.popup"
    tk_popup $windowName.popup [winfo pointerx $windowName] \
        [winfo pointery $windowName] 0
}

proc ::dialog_array::listview_copy {arrayName} {
    set windowName [format ".%sArrayWindow" $arrayName]
    set itemNums [$windowName.lb curselection]
    set cbString ""
    for {set i 0} {$i < [expr [llength $itemNums] - 1]} {incr i} {
        set listItem [$windowName.lb get [lindex $itemNums $i]]
        append cbString [string range $listItem \
                             [expr [string first ") " $listItem] + 2] \
                             end]
        append cbString "\n"
    }
    set listItem [$windowName.lb get [lindex $itemNums $i]]
    append cbString [string range $listItem \
                         [expr [string first ") " $listItem] + 2] \
                         end]
    clipboard clear
    clipboard append $cbString
}

proc ::dialog_array::listview_paste {arrayName} {
    set cbString [selection get -selection CLIPBOARD]
    set lbName [format ".%sArrayWindow.lb" $arrayName]
    set itemNum [lindex [$lbName curselection] 0]
    set splitChars ", \n"
    set itemString [split $cbString $splitChars]
    set flag 1
    for {set i 0; set counter 0} {$i < [llength $itemString]} {incr i} {
        if {[lindex $itemString $i] ne {}} {
            pdsend {$arrayName [expr $itemNum + \
                                       [expr $counter + \
                                            [expr $::pd_array_listview_pagesize \
                                                 * $::pd_array_listview_page($arrayName)]]] \
                    [lindex $itemString $i]}
            incr counter
            set flag 0
        }
    }
}

proc ::dialog_array::listview_edit {arrayName page font} {
    set lbName [format ".%sArrayWindow.lb" $arrayName]
    if {[winfo exists $lbName.entry]} {
        ::dialog_array::listview_update_entry \
            $arrayName $::pd_array_listview_entry($arrayName)
        unset ::pd_array_listview_entry($arrayName)
    }
    set itemNum [$lbName index active]
    set ::pd_array_listview_entry($arrayName) $itemNum
    set bbox [$lbName bbox $itemNum]
    set y [expr [lindex $bbox 1] - 4]
    set $lbName.entry [entry $lbName.entry \
                           -font [format {{%s} %d %s} $::font_family $font $::font_weight]]
    $lbName.entry insert 0 []
    place configure $lbName.entry -relx 0 -y $y -relwidth 1
    lower $lbName.entry
    focus $lbName.entry
    bind $lbName.entry <Return> \
        "::dialog_array::listview_update_entry $arrayName $itemNum;"
}

proc ::dialog_array::listview_update_entry {arrayName itemNum} {
    set lbName [format ".%sArrayWindow.lb" $arrayName]
    set splitChars ", \n"
    set itemString [split [$lbName.entry get] $splitChars]
    set flag 1
    for {set i 0; set counter 0} {$i < [llength $itemString]} {incr i} {
        if {[lindex $itemString $i] ne {}} {
            pdsend {$arrayName [expr $itemNum + \
                                       [expr $counter + \
                                            [expr $::pd_array_listview_pagesize \
                                                 * $::pd_array_listview_page($arrayName)]]] \
                    [lindex $itemString $i]}
            incr counter
            set flag 0
        }
    }
    pdtk_array_listview_fillpage $arrayName
    destroy $lbName.entry
}

proc ::dialog_array::pdtk_array_listview_closeWindow {arrayName} {
    set mytoplevel [format ".%sArrayWindow" $arrayName]
    destroy $mytoplevel
}

proc ::dialog_array::listview_close {mytoplevel arrayName} {
    pdtk_array_listview_closeWindow $arrayName
    pdsend "$mytoplevel arrayviewclose"
}

proc ::dialog_array::apply {mytoplevel} {
    pdsend "$mytoplevel arraydialog \
            [::dialog_gatom::escape [$::w.array.nameEntry get]] \
            [$::w.array.sizeEntry get] \
            [expr $::saveme_button($mytoplevel) + (2 * $::drawas_button($mytoplevel))] \
            $::otherflag_button($mytoplevel)"
}

proc ::dialog_array::openlistview {mytoplevel} {
    pdsend "$mytoplevel arrayviewlistnew"
}

proc ::dialog_array::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

proc ::dialog_array::ok {mytoplevel} {
    ::dialog_array::apply $mytoplevel
    ::dialog_array::cancel $mytoplevel
}

proc ::dialog_array::pdtk_array_dialog {mytoplevel name size flags newone} {
    if {[winfo exists $mytoplevel]} {
        wm deiconify $mytoplevel
        raise $mytoplevel
        focus $mytoplevel
    } else {
        create_dialog $mytoplevel $newone
    }

    $::w.array.nameEntry insert 0 [::dialog_gatom::unescape $name]
    $::w.array.sizeEntry insert 0 $size
    set ::saveme_button($mytoplevel) [expr $flags & 1]
    set ::drawas_button($mytoplevel) [expr ( $flags & 6 ) >> 1]
    set ::otherflag_button($mytoplevel) 0
# pd -> tcl
#  2 * (int)(template_getfloat(template_findbyname(sc->sc_template), gensym("style"), x->x_scalar->sc_vec, 1)));

# tcl->pd
#    int style = ((flags & 6) >> 1);
}

proc ::dialog_array::create_dialog {mytoplevel newone} {
    toplevel $mytoplevel -class DialogWindow
    wm title $mytoplevel "Array Properties"
    wm group $mytoplevel .
    wm resizable $mytoplevel 0 0
    wm transient $mytoplevel $::focused_window
    $mytoplevel configure -menu $::dialog_menubar
    $mytoplevel configure -padx 0 -pady 0
    ::pd_bindings::dialog_bindings $mytoplevel "array"

# Widgets
    ttk::frame $mytoplevel.windowFrame -padding 5 
    set ::w $mytoplevel.windowFrame

    ttk::labelframe $::w.array -borderwidth 1 -text " Array "  \
                               -padding 4
    ttk::label $::w.array.nameLabel -text "Name:" 
    ttk::entry $::w.array.nameEntry -width 17 
    ttk::label $::w.array.sizeLabel -text "Size:" 
    ttk::entry $::w.array.sizeEntry -width 17 
    ttk::label $::w.array.savemeLabel -text "Save Contents" 
    ttk::checkbutton $::w.array.saveme \
        -variable ::saveme_button($mytoplevel)

    # draw as
    ttk::labelframe $::w.drawas -text " Style "  -padding "0 4"
    if {$newone == 0} {
        ttk::frame $::w.drawas.pad -width 18
    }
    ttk::radiobutton $::w.drawas.points -value 0  \
        -variable ::drawas_button($mytoplevel) -text "Polygon"
    ttk::radiobutton $::w.drawas.polygon -value 1  \
        -variable ::drawas_button($mytoplevel) -text "Points"
    ttk::radiobutton $::w.drawas.bezier -value 2  \
        -variable ::drawas_button($mytoplevel) -text "Bezier"

    # options
    if {$newone == 1} {
        ttk::labelframe $::w.options -text " Graph Select "  \
                                     -padding "0 4 0 0"
       
        ttk::radiobutton $::w.options.radio0 -value 0  \
            -variable ::otherflag_button($mytoplevel) -text "New graph"
        ttk::radiobutton $::w.options.radio1 -value 1  \
            -variable ::otherflag_button($mytoplevel) -text "Last graph"
    } else {
        ttk::button $::w.listview -text "Open List View" -width 12  \
            -command "::dialog_array::openlistview $mytoplevel [$::w.array.nameEntry get]"
        ttk::separator $::w.sep 
    }

    # buttons
    ttk::frame $::w.buttonframe 
    if {$newone == 1} {
        ttk::frame $::w.buttonframe.pad -width 22
    }
    ttk::button $::w.buttonframe.cancel -text "Cancel"  \
        -command "::dialog_array::cancel $mytoplevel"
    # WARN this was dependent on newone == 0
    ttk::button $::w.buttonframe.apply -text "Apply"  \
        -command "::dialog_array::apply $mytoplevel"
    ttk::button $::w.buttonframe.ok -text "OK"  \
        -command "::dialog_array::ok $mytoplevel" -default active

# Layout
    grid $::w -column 0 -row 0 -sticky nwes
    grid $::w.array -column 0 -row 0 -sticky nwes
    grid $::w.array.nameLabel   -column 0 -row 0 -sticky w
    grid $::w.array.nameEntry   -column 1 -row 0 -sticky w
    grid $::w.array.sizeLabel   -column 0 -row 1 -sticky w
    grid $::w.array.sizeEntry   -column 1 -row 1 -sticky w -pady 4
    grid $::w.array.saveme      -column 0 -row 2
    grid $::w.array.savemeLabel -column 1 -row 2 -sticky w

    grid $::w.drawas -column 0 -row 1 -sticky nwes -pady 4
    if {$newone == 0} {
        grid $::w.drawas.pad -column 0 -row 0
    }
    grid $::w.drawas.points  -column 1 -row 0
    grid $::w.drawas.polygon -column 2 -row 0 -padx 10
    grid $::w.drawas.bezier  -column 3 -row 0

    if {$newone == 1} {
        grid $::w.options -column 0 -row 2 -sticky nwes
        grid $::w.options.radio0 -column 0 -row 0 -padx 4
        grid $::w.options.radio1 -column 0 -row 1 -padx 4 -pady 2
    } else {
        grid $::w.listview -column 0 -row 2 -sticky w -pady 4
        grid $::w.sep -column 0 -row 3 -sticky we
    }

    # todo these if statements are a little sloppy
    grid $::w.buttonframe -column 0 -row 4 -sticky nwes 
    if {$newone == 1} {
        grid $::w.buttonframe.pad -column 0 -row 0
    }
    grid $::w.buttonframe.ok -column 1 -row 0 -pady 4
    if {$newone != 1} {
        grid $::w.buttonframe.apply -column 2 -row 0
    }
    grid $::w.buttonframe.cancel -column 3 -row 0


# live widget updates on OSX in lieu of Apply button
    if {$::windowingsystem eq "aqua"} {

        # only bind if there is an existing array to edit
        if {$newone == 0} {

            # call apply on button changes
            $::w.array.saveme config -command [ concat ::dialog_array::apply $mytoplevel ]
            $::w.drawas.points config -command [ concat ::dialog_array::apply $mytoplevel ]
            $::w.drawas.polygon config -command [ concat ::dialog_array::apply $mytoplevel ]
            $::w.drawas.bezier config -command [ concat ::dialog_array::apply $mytoplevel ]

            # call apply on Return in entry boxes that are in focus & rebind Return to ok button
            bind $::w.array.nameEntry <KeyPress-Return> "::dialog_array::apply_and_rebind_return $mytoplevel"
            bind $::w.array.sizeEntry <KeyPress-Return> "::dialog_array::apply_and_rebind_return $mytoplevel"

            # unbind Return from ok button when an entry takes focus
            $::w.array.nameEntry config -validate focusin -validatecommand "::dialog_array::unbind_return $mytoplevel"
            $::w.array.sizeEntry config -validate focusin -validatecommand "::dialog_array::unbind_return $mytoplevel"
        }

        # remove cancel button from focus list since it's not activated on Return
        $::w.buttonframe.cancel config -takefocus 0

        # show active focus on the ok button as it *is* activated on Return
        $::w.buttonframe.ok config -default normal
        bind $::w.buttonframe.ok <FocusIn> "$::w.buttonframe.ok config -default active"
        bind $::w.buttonframe.ok <FocusOut> "$::w.buttonframe.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        # $::w.buttonframe.ok config -highlightthickness 0
        # $::w.buttonframe.cancel config -highlightthickness 0
    }

    position_over_window "$mytoplevel" "$::focused_window"
}

# for live widget updates on OSX
proc ::dialog_array::apply_and_rebind_return {mytoplevel} {
    ::dialog_array::apply $mytoplevel
    bind $mytoplevel <KeyPress-Return> "::dialog_array::ok $mytoplevel"
    focus $::w.buttonframe.ok
    return 0
}

# for live widget updates on OSX
proc ::dialog_array::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> break
    return 1
}
