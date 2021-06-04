# TODO offset this panel so it doesn't overlap the pdtk_array panel
# TODO there's some bug when messing with hide graph on parent and it's an array canvas

package provide dialog_canvas 0.1

namespace eval ::dialog_canvas:: {
    namespace export pdtk_canvas_dialog
}

# global variables to store checkbox state on canvas properties window.  These
# are only used in the context of getting data from the checkboxes, so they
# aren't really useful elsewhere.  It would be nice to have them globally
# useful, but that would mean changing the C code.
array set graphme_button {}
array set hidetext_button {}

############# pdtk_canvas_dialog -- dialog window for canvases #################

proc ::dialog_canvas::apply {mytoplevel} {
    global graphme_button
    global hidetext_button

    pdsend "$mytoplevel donecanvasdialog \
            [$::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry get] \
            [$::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry get] \
            [expr $graphme_button($mytoplevel) + 2 * $hidetext_button($mytoplevel)] \
            [$::cnvWin.winFrame.rngAndScale.x.fromEntry get] \
            [$::cnvWin.winFrame.rngAndScale.y.fromEntry get] \
            [$::cnvWin.winFrame.rngAndScale.x.toEntry get] \
            [$::cnvWin.winFrame.rngAndScale.y.toEntry get] \
            [$::cnvWin.winFrame.appearance.entries.widthEntry get] \
            [$::cnvWin.winFrame.appearance.entries.heightEntry get] \
            [$::cnvWin.winFrame.appearance.entries.xPosEntry get] \
            [$::cnvWin.winFrame.appearance.entries.yPosEntry get] 1"
}

proc ::dialog_canvas::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

proc ::dialog_canvas::ok {mytoplevel} {
    ::dialog_canvas::apply $mytoplevel
    ::dialog_canvas::cancel $mytoplevel
}

proc ::dialog_canvas::checkcommand {mytoplevel} {
    global graphme_button

    if { $graphme_button($mytoplevel) != 0 } {
        $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry configure -state disabled -takefocus 0
        $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry configure -state disabled -takefocus 0
        $::cnvWin.winFrame.appearance.hidetext configure -state normal
        $::cnvWin.winFrame.rngAndScale.x.fromEntry configure -state normal
        $::cnvWin.winFrame.rngAndScale.x.toEntry configure -state normal
        $::cnvWin.winFrame.appearance.entries.widthEntry configure -state normal
        $::cnvWin.winFrame.appearance.entries.xPosEntry configure -state normal
        $::cnvWin.winFrame.rngAndScale.y.fromEntry configure -state normal
        $::cnvWin.winFrame.rngAndScale.y.toEntry configure -state normal
        $::cnvWin.winFrame.appearance.entries.heightEntry configure -state normal
        $::cnvWin.winFrame.appearance.entries.yPosEntry configure -state normal
        if { [$::cnvWin.winFrame.rngAndScale.x.fromEntry get] == 0 \
                 && [$::cnvWin.winFrame.rngAndScale.y.fromEntry get] == 0 \
                 && [$::cnvWin.winFrame.rngAndScale.x.toEntry get] == 0 \
                 && [$::cnvWin.winFrame.rngAndScale.y.toEntry get] == 0 } {
            $::cnvWin.winFrame.rngAndScale.y.toEntry insert 0 1
            $::cnvWin.winFrame.rngAndScale.y.toEntry insert 0 1
        }
        if { [$::cnvWin.winFrame.appearance.entries.widthEntry get] == 0 } {
            $::cnvWin.winFrame.appearance.entries.widthEntry delete 0 end
            $::cnvWin.winFrame.appearance.entries.xPosEntry delete 0 end
            $::cnvWin.winFrame.appearance.entries.widthEntry insert 0 85
            $::cnvWin.winFrame.appearance.entries.xPosEntry insert 0 100
        }
        if { [$::cnvWin.winFrame.appearance.entries.heightEntry get] == 0 } {
            $::cnvWin.winFrame.appearance.entries.heightEntry delete 0 end
            $::cnvWin.winFrame.appearance.entries.yPosEntry delete 0 end
            $::cnvWin.winFrame.appearance.entries.heightEntry insert 0 60
            $::cnvWin.winFrame.appearance.entries.yPosEntry insert 0 100
       }
    } else {
        $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry configure -state normal -takefocus 1
        $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry configure -state normal -takefocus 1
        $::cnvWin.winFrame.appearance.hidetext configure -state disabled
        $::cnvWin.winFrame.rngAndScale.x.fromEntry configure -state disabled
        $::cnvWin.winFrame.rngAndScale.x.toEntry configure -state disabled
        $::cnvWin.winFrame.appearance.entries.widthEntry configure -state disabled
        $::cnvWin.winFrame.appearance.entries.xPosEntry configure -state disabled
        $::cnvWin.winFrame.rngAndScale.y.fromEntry configure -state disabled
        $::cnvWin.winFrame.rngAndScale.y.toEntry configure -state disabled
        $::cnvWin.winFrame.appearance.entries.heightEntry configure -state disabled
        $::cnvWin.winFrame.appearance.entries.yPosEntry configure -state disabled
        if { [$::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry get] == 0 } {
            $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry delete 0 end
            $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry insert 0 1
        }
        if { [$::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry get] == 0 } {
            $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry delete 0 end
            $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry insert 0 1
        }
    }
}

proc ::dialog_canvas::pdtk_canvas_dialog {mytoplevel xscale yscale graphmeflags \
                                          xfrom yfrom xto yto \
                                          xsize ysize xmargin ymargin} {
    if {[winfo exists $mytoplevel]} {
        wm deiconify $mytoplevel
        raise $mytoplevel
        focus $mytoplevel
    } else {
        create_dialog $mytoplevel
    }

    global graphme_button
    global hidetext_button
    switch -- $graphmeflags {
        0 {
            set graphme_button($mytoplevel) 0
            set hidetext_button($mytoplevel) 0
        } 1 {
            set graphme_button($mytoplevel) 1
            set hidetext_button($mytoplevel) 0
        } 2 {
            set graphme_button($mytoplevel) 0
            set hidetext_button($mytoplevel) 1
        } 3 {
            set graphme_button($mytoplevel) 1
            set hidetext_button($mytoplevel) 1
        } default {
            ::pdwindow::error [_ "WARNING: unknown graphme flags received in pdtk_canvas_dialog"]
        }
    }

    $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry insert 0 $xscale
    $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry insert 0 $yscale
    $::cnvWin.winFrame.rngAndScale.x.fromEntry insert 0 $xfrom
    $::cnvWin.winFrame.rngAndScale.y.fromEntry insert 0 $yfrom
    $::cnvWin.winFrame.rngAndScale.x.toEntry insert 0 $xto
    $::cnvWin.winFrame.rngAndScale.y.toEntry insert 0 $yto
    $::cnvWin.winFrame.appearance.entries.widthEntry insert 0 $xsize
    $::cnvWin.winFrame.appearance.entries.heightEntry insert 0 $ysize
    $::cnvWin.winFrame.appearance.entries.xPosEntry insert 0 $xmargin
    $::cnvWin.winFrame.appearance.entries.yPosEntry insert 0 $ymargin

   ::dialog_canvas::checkcommand $mytoplevel
}

proc ::dialog_canvas::create_dialog {mytoplevel} {
    toplevel $mytoplevel
    wm title $mytoplevel "Canvas Properties"
    wm group $mytoplevel .
    wm resizable $mytoplevel 0 0
    wm transient $mytoplevel $::focused_window
    $mytoplevel configure -menu $::dialog_menubar
    $mytoplevel configure -padx 0 -pady 0
    ::pd_bindings::dialog_bindings $mytoplevel "canvas"
    set ::cnvWin $mytoplevel

    global graphme_button
    global hidetext_button

# Widgets
    ttk::frame $::cnvWin.winFrame -padding 3

    ttk::labelframe $::cnvWin.winFrame.appearance -text " Appearance " -padding 4 

    ttk::checkbutton $::cnvWin.winFrame.appearance.graphme -text "Graph on Parent" \
        -variable graphme_button($mytoplevel)  \
        -command [concat ::dialog_canvas::checkcommand $mytoplevel]
    ttk::checkbutton $::cnvWin.winFrame.appearance.hidetext -text "Hide name and arguments" \
        -variable hidetext_button($mytoplevel)  \
        -command [concat ::dialog_canvas::checkcommand $mytoplevel]
    
    ttk::frame $::cnvWin.winFrame.appearance.pad -width 40 
    ttk::separator $::cnvWin.winFrame.appearance.sep
    ttk::frame $::cnvWin.winFrame.appearance.entries 
    ttk::label $::cnvWin.winFrame.appearance.entries.widthLabel -text "Width:" 
    ttk::entry $::cnvWin.winFrame.appearance.entries.widthEntry -width 4 
    ttk::label $::cnvWin.winFrame.appearance.entries.heightLabel -text "Height:" 
    ttk::entry $::cnvWin.winFrame.appearance.entries.heightEntry -width 4 
    ttk::label $::cnvWin.winFrame.appearance.entries.xPosLabel -text "X Position:" 
    ttk::entry $::cnvWin.winFrame.appearance.entries.xPosEntry -width 4 
    ttk::label $::cnvWin.winFrame.appearance.entries.yPosLabel -text "Y Position:" 
    ttk::entry $::cnvWin.winFrame.appearance.entries.yPosEntry -width 4 

    ttk::labelframe $::cnvWin.winFrame.rngAndScale -text " Range/Scale " -padding 4 
    ttk::frame $::cnvWin.winFrame.rngAndScale.x 
    ttk::frame $::cnvWin.winFrame.rngAndScale.y 

    ttk::separator $::cnvWin.winFrame.rngAndScale.x.left
    ttk::label $::cnvWin.winFrame.rngAndScale.x.header -text "X" 
    ttk::separator $::cnvWin.winFrame.rngAndScale.x.right

    ttk::label $::cnvWin.winFrame.rngAndScale.x.fromLabel -text "From:" 
    ttk::entry $::cnvWin.winFrame.rngAndScale.x.fromEntry -width 4 
    ttk::label $::cnvWin.winFrame.rngAndScale.x.toLabel -text "To:" 
    ttk::entry $::cnvWin.winFrame.rngAndScale.x.toEntry -width 4 
    ttk::label $::cnvWin.winFrame.rngAndScale.x.unitsPerPxLabel -text "Units per Pixel:" 
    ttk::entry $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry -width 4 
    ttk::frame $::cnvWin.winFrame.rngAndScale.x.pad -width 100 

    ttk::separator $::cnvWin.winFrame.rngAndScale.y.left
    ttk::label $::cnvWin.winFrame.rngAndScale.y.header -text "Y" 
    ttk::separator $::cnvWin.winFrame.rngAndScale.y.right

    ttk::label $::cnvWin.winFrame.rngAndScale.y.fromLabel -text "From:" 
    ttk::entry $::cnvWin.winFrame.rngAndScale.y.fromEntry -width 4 
    ttk::label $::cnvWin.winFrame.rngAndScale.y.toLabel -text "To:" 
    ttk::entry $::cnvWin.winFrame.rngAndScale.y.toEntry -width 4 
    ttk::label $::cnvWin.winFrame.rngAndScale.y.unitsPerPxLabel -text "Units per Pixel:" 
    ttk::entry $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry -width 4 
    ttk::frame $::cnvWin.winFrame.rngAndScale.y.pad -width 100 

    ttk::frame $::cnvWin.winFrame.buttons 
    ttk::button $::cnvWin.winFrame.buttons.cancel -text "Cancel"  \
        -command "::dialog_canvas::cancel $mytoplevel"
    ttk::button $::cnvWin.winFrame.buttons.apply -text "Apply"  \
        -command "::dialog_canvas::apply $mytoplevel"
    ttk::button $::cnvWin.winFrame.buttons.ok -text "OK"  \
        -command "::dialog_canvas::ok $mytoplevel" -default active
# Layout
    grid $::cnvWin.winFrame -column 0 -row 0

    grid $::cnvWin.winFrame.appearance -column 0 -row 0 -sticky nwes
    grid $::cnvWin.winFrame.appearance.graphme -column 0 -row 0 -sticky w
    grid $::cnvWin.winFrame.appearance.hidetext -column 0 -row 1 -sticky w -pady 1
    grid $::cnvWin.winFrame.appearance.pad -column 1 -row 1
    grid $::cnvWin.winFrame.appearance.sep -column 0 -row 2 -sticky we -columnspan 2 -pady 2
    grid $::cnvWin.winFrame.appearance.entries -column 0 -row 3
    grid $::cnvWin.winFrame.appearance.entries.widthLabel  -column 0 -row 0 -sticky w
    grid $::cnvWin.winFrame.appearance.entries.widthEntry  -column 1 -row 0
    grid $::cnvWin.winFrame.appearance.entries.heightLabel -column 2 -row 0 -sticky w
    grid $::cnvWin.winFrame.appearance.entries.heightEntry -column 3 -row 0
    grid $::cnvWin.winFrame.appearance.entries.xPosLabel -column 0 -row 1
    grid $::cnvWin.winFrame.appearance.entries.xPosEntry -column 1 -row 1 -pady 2
    grid $::cnvWin.winFrame.appearance.entries.yPosLabel -column 2 -row 1
    grid $::cnvWin.winFrame.appearance.entries.yPosEntry -column 3 -row 1

    grid $::cnvWin.winFrame.rngAndScale -column 0 -row 1 -sticky nwes
    grid $::cnvWin.winFrame.rngAndScale.x -column 0 -row 0 -sticky nwes

    grid $::cnvWin.winFrame.rngAndScale.x.left -column 0 -row 0 -sticky we
    grid $::cnvWin.winFrame.rngAndScale.x.header -column 1 -row 0
    grid $::cnvWin.winFrame.rngAndScale.x.right -column 2 -row 0 -sticky we -columnspan 4
    grid $::cnvWin.winFrame.rngAndScale.x.fromLabel -column 0 -row 1 -columnspan 2
    grid $::cnvWin.winFrame.rngAndScale.x.fromEntry -column 2 -row 1
    grid $::cnvWin.winFrame.rngAndScale.x.toLabel -column 3 -row 1
    grid $::cnvWin.winFrame.rngAndScale.x.toEntry -column 4 -row 1
    grid $::cnvWin.winFrame.rngAndScale.x.unitsPerPxLabel -column 0 -row 2 -columnspan 4 -sticky w
    grid $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry -column 4 -row 2 -sticky w -pady 2
    grid $::cnvWin.winFrame.rngAndScale.x.pad -column 5 -row 2

    grid $::cnvWin.winFrame.rngAndScale.y -column 0 -row 1 -sticky nwes

    grid $::cnvWin.winFrame.rngAndScale.y.left -column 0 -row 0 -sticky we
    grid $::cnvWin.winFrame.rngAndScale.y.header -column 1 -row 0
    grid $::cnvWin.winFrame.rngAndScale.y.right -column 2 -row 0 -sticky we -columnspan 4
    grid $::cnvWin.winFrame.rngAndScale.y.fromLabel -column 0 -row 1 -columnspan 2
    grid $::cnvWin.winFrame.rngAndScale.y.fromEntry -column 2 -row 1
    grid $::cnvWin.winFrame.rngAndScale.y.toLabel -column 3 -row 1
    grid $::cnvWin.winFrame.rngAndScale.y.toEntry -column 4 -row 1
    grid $::cnvWin.winFrame.rngAndScale.y.unitsPerPxLabel -column 0 -row 2 -columnspan 4 -sticky w
    grid $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry -column 4 -row 2 -sticky w -pady 2
    grid $::cnvWin.winFrame.rngAndScale.y.pad -column 5 -row 2
    
    grid $::cnvWin.winFrame.buttons -column 0 -row 5 -pady 4
    grid $::cnvWin.winFrame.buttons.ok -column 0 -row 5 
    grid $::cnvWin.winFrame.buttons.apply -column 1 -row 5
    grid $::cnvWin.winFrame.buttons.cancel -column 2 -row 5

# live checkbutton & entry Return updates on OSX
    if {$::windowingsystem eq "aqua"} {

        # call apply on checkbutton changes
        $::cnvWin.winFrame.appearance.graphme config -command [ concat ::dialog_canvas::checkcommand_and_apply $mytoplevel ]
        $::cnvWin.winFrame.appearance.hidetext config -command [ concat ::dialog_canvas::checkcommand_and_apply $mytoplevel ]

        # call apply on Return in entry boxes that are in focus & rebind Return to ok button
        bind $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.rngAndScale.x.fromEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.rngAndScale.y.fromEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.rngAndScale.x.toEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.rngAndScale.y.toEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.appearance.entries.widthEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.appearance.entries.heightEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.appearance.entries.xPosEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"
        bind $::cnvWin.winFrame.appearance.entries.yPosEntry <KeyPress-Return> "::dialog_canvas::apply_and_rebind_return $mytoplevel"

        # unbind Return from ok button when an entry takes focus
        $::cnvWin.winFrame.rngAndScale.x.unitsPerPxEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.rngAndScale.y.unitsPerPxEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.rngAndScale.x.fromEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.rngAndScale.y.fromEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.rngAndScale.x.toEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.rngAndScale.y.toEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.appearance.entries.widthEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.appearance.entries.heightEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.appearance.entries.xPosEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"
        $::cnvWin.winFrame.appearance.entries.yPosEntry config -validate focusin -validatecommand "::dialog_canvas::unbind_return $mytoplevel"

        # remove cancel button from focus list since it's not activated on Return
        $::cnvWin.winFrame.buttons.cancel config -takefocus 0

        # show active focus on the ok button as it *is* activated on Return
        $::cnvWin.winFrame.buttons.ok config -default normal
        bind $::cnvWin.winFrame.buttons.ok <FocusIn> "$::cnvWin.winFrame.buttons.ok config -default active"
        bind $::cnvWin.winFrame.buttons.ok <FocusOut> "$::cnvWin.winFrame.buttons.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        # my theme doesn't do anything with this and ttk::widgets want this to be done with ttk::style
        # $::cnvWin.winFrame.buttons.ok config -highlightthickness 0
        # $::cnvWin.winFrame.buttons.cancel config -highlightthickness 0
    }

    position_over_window $mytoplevel $::focused_window
}

# for live updates on OSX
proc ::dialog_canvas::checkcommand_and_apply {mytoplevel} {
    ::dialog_canvas::checkcommand $mytoplevel
    ::dialog_canvas::apply $mytoplevel
}

    # for live widget updates on OSX
proc ::dialog_canvas::apply_and_rebind_return {mytoplevel} {
    ::dialog_canvas::apply $mytoplevel
    bind $mytoplevel <KeyPress-Return> "::dialog_canvas::ok $mytoplevel"
    focus $::cnvWin.winFrame.buttons.ok
    return 0
}

# for live widget updates on OSX
proc ::dialog_canvas::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> break
    return 1
}
