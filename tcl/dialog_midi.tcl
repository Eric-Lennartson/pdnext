package provide dialog_midi 0.1

namespace eval ::dialog_midi:: {
    namespace export pdtk_midi_dialog
    namespace export pdtk_alsa_midi_dialog
}

####################### midi dialog ##################

proc ::dialog_midi::apply {mytoplevel} {
    global midi_indev1 midi_indev2 midi_indev3 midi_indev4 midi_indev5 \
        midi_indev6 midi_indev7 midi_indev8 midi_indev9
    global midi_outdev1 midi_outdev2 midi_outdev3 midi_outdev4 midi_outdev5 \
        midi_outdev6 midi_outdev7 midi_outdev8 midi_outdev9
    global midi_alsain midi_alsaout

    pdsend "pd midi-dialog \
        $midi_indev1 \
        $midi_indev2 \
        $midi_indev3 \
        $midi_indev4 \
        $midi_indev5 \
        $midi_indev6 \
        $midi_indev7 \
        $midi_indev8 \
        $midi_indev9 \
        $midi_outdev1 \
        $midi_outdev2 \
        $midi_outdev3 \
        $midi_outdev4 \
        $midi_outdev5 \
        $midi_outdev6 \
        $midi_outdev7 \
        $midi_outdev8 \
        $midi_outdev9 \
        $midi_alsain \
        $midi_alsaout"
}

proc ::dialog_midi::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

proc ::dialog_midi::ok {mytoplevel} {
    ::dialog_midi::apply $mytoplevel
    ::dialog_midi::cancel $mytoplevel
}

# callback from popup menu
proc midi_popup_action {buttonname varname devlist index} {
    global midi_indevlist midi_outdevlist $varname
    $buttonname configure -text [lindex $devlist $index]
    set $varname $index
}

# create a popup menu
proc midi_popup {name buttonname varname devlist} {
    if [winfo exists $name.popup] {destroy $name.popup}
    menu $name.popup -tearoff false
    if {$::windowingsystem eq "win32"} {
        $name.popup configure -font menuFont
    }
    #puts stderr [concat $devlist ]
    for {set x 0} {$x<[llength $devlist]} {incr x} {
        $name.popup add command -label [lindex $devlist $x] \
            -command [list midi_popup_action \
                $buttonname $varname $devlist $x]
    }
    # open popup over source button
    set x [expr [winfo rootx $buttonname] + ( [winfo width $buttonname] / 2 )]
    set y [expr [winfo rooty $buttonname] + ( [winfo height $buttonname] / 2 )]
    tk_popup $name.popup $x $y 0
}

# start a dialog window to select midi devices.
# UNUSED is where "longform" used to be
# I think we should just show all the buttons at once
proc ::dialog_midi::pdtk_midi_dialog {mytoplevel \
      indev1 indev2 indev3 indev4 indev5 indev6 indev7 indev8 indev9 \
      outdev1 outdev2 outdev3 outdev4 outdev5 outdev6 outdev7 outdev8 outdev9 \
      UNUSED} {
    global midi_indev1 midi_indev2 midi_indev3 midi_indev4 midi_indev5 \
         midi_indev6 midi_indev7 midi_indev8 midi_indev9
    global midi_outdev1 midi_outdev2 midi_outdev3 midi_outdev4 midi_outdev5 \
         midi_outdev6 midi_outdev7 midi_outdev8 midi_outdev9
    global midi_indevlist midi_outdevlist
    global midi_alsain midi_alsaout

    set midi_indev1 $indev1
    set midi_indev2 $indev2
    set midi_indev3 $indev3
    set midi_indev4 $indev4
    set midi_indev5 $indev5
    set midi_indev6 $indev6
    set midi_indev7 $indev7
    set midi_indev8 $indev8
    set midi_indev9 $indev9
    set midi_outdev1 $outdev1
    set midi_outdev2 $outdev2
    set midi_outdev3 $outdev3
    set midi_outdev4 $outdev4
    set midi_outdev5 $outdev5
    set midi_outdev6 $outdev6
    set midi_outdev7 $outdev7
    set midi_outdev8 $outdev8
    set midi_outdev9 $outdev9
    set midi_alsain [llength $midi_indevlist]
    set midi_alsaout [llength $midi_outdevlist]

    toplevel $mytoplevel
    wm withdraw $mytoplevel
    wm title $mytoplevel "MIDI Settings"
    wm group $mytoplevel .
    wm resizable $mytoplevel 0 0
    wm transient $mytoplevel
    $mytoplevel configure -menu $::dialog_menubar
    ::pd_bindings::dialog_bindings $mytoplevel "midi"

# Widgets
    # ins and outs probably could've been put into a for loop
    # but I think it would be less readable
    ttk::frame $mytoplevel.w -padding 5
    set ::midiWin $mytoplevel.w

    # input devices
    ttk::labelframe $::midiWin.inputs -text " Input Devices " -padding 5

    # input device 1
    ttk::label $::midiWin.inputs.in1Label -text "1:"
    ttk::button $::midiWin.inputs.in1Select -text [lindex $midi_indevlist $midi_indev1] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in1Select midi_indev1 $midi_indevlist] \
        -width 20
    
    # input device 2
    ttk::label $::midiWin.inputs.in2Label -text "2:"
    ttk::button $::midiWin.inputs.in2Select -text [lindex $midi_indevlist $midi_indev2] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in2Select midi_indev2 \
            $midi_indevlist] -width 20

    # input device 3
    ttk::label $::midiWin.inputs.in3Label -text "3:"
    ttk::button $::midiWin.inputs.in3Select -text [lindex $midi_indevlist $midi_indev3] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in3Select midi_indev3 \
            $midi_indevlist] -width 20

    # input device 4
    ttk::label $::midiWin.inputs.in4Label -text "4:"
    ttk::button $::midiWin.inputs.in4Select -text [lindex $midi_indevlist $midi_indev4] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in4Select midi_indev4 \
            $midi_indevlist] -width 20

    # input device 5
    ttk::label $::midiWin.inputs.in5Label -text "5:"
    ttk::button $::midiWin.inputs.in5Select -text [lindex $midi_indevlist $midi_indev5] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in5Select midi_indev5 \
            $midi_indevlist] -width 20

    # input device 6
    ttk::label $::midiWin.inputs.in6Label -text "6:"
    ttk::button $::midiWin.inputs.in6Select -text [lindex $midi_indevlist $midi_indev6] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in6Select midi_indev6 \
            $midi_indevlist] -width 20

    # input device 7
    ttk::label $::midiWin.inputs.in7Label -text "7:" 
    ttk::button $::midiWin.inputs.in7Select -text [lindex $midi_indevlist $midi_indev7] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in7Select midi_indev7 \
            $midi_indevlist]  -width 20

    # input device 8
    ttk::label $::midiWin.inputs.in8Label -text "8:" 
    ttk::button $::midiWin.inputs.in8Select -text [lindex $midi_indevlist $midi_indev8] \
        -command [list midi_popup $mytoplevel $::midiWin.inputs.in8Select midi_indev8 \
            $midi_indevlist]  -width 20

    # output devices
    ttk::labelframe $::midiWin.outputs -text " Output Devices " -padding 5
    
    # output device 1
    ttk::label $::midiWin.outputs.out1Label -text "1:" 
    ttk::button $::midiWin.outputs.out1Select -text [lindex $midi_outdevlist $midi_outdev1] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out1Select midi_outdev1 \
            $midi_outdevlist]  -width 20

    # output device 2
    ttk::label $::midiWin.outputs.out2Label -text "2:" 
    ttk::button $::midiWin.outputs.out2Select -text [lindex $midi_outdevlist $midi_outdev2] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out2Select midi_outdev2 $midi_outdevlist] \
         -width 20

    # output device 3
    ttk::label $::midiWin.outputs.out3Label -text "3:" 
    ttk::button $::midiWin.outputs.out3Select -text [lindex $midi_outdevlist $midi_outdev3] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out3Select midi_outdev3 $midi_outdevlist] \
         -width 20

    # output device 4
    ttk::label $::midiWin.outputs.out4Label -text "4:" 
    ttk::button $::midiWin.outputs.out4Select -text [lindex $midi_outdevlist $midi_outdev4] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out4Select midi_outdev4 $midi_outdevlist] \
         -width 20

    # output device 5
    ttk::label $::midiWin.outputs.out5Label -text "5:" 
    ttk::button $::midiWin.outputs.out5Select -text [lindex $midi_outdevlist $midi_outdev5] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out5Select midi_outdev5 $midi_outdevlist] \
         -width 20

    # output device 6
    ttk::label $::midiWin.outputs.out6Label -text "6:" 
    ttk::button $::midiWin.outputs.out6Select -text [lindex $midi_outdevlist $midi_outdev6] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out6Select midi_outdev6 $midi_outdevlist] \
         -width 20

    # output device 7
    ttk::label $::midiWin.outputs.out7Label -text "7:" 
    ttk::button $::midiWin.outputs.out7Select -text [lindex $midi_outdevlist $midi_outdev7] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out7Select midi_outdev7 $midi_outdevlist] \
         -width 20

    # output device 8
    ttk::label $::midiWin.outputs.out8Label -text "8:" 
    ttk::button $::midiWin.outputs.out8Select -text [lindex $midi_outdevlist $midi_outdev8] \
        -command [list midi_popup $mytoplevel $::midiWin.outputs.out8Select midi_outdev8 $midi_outdevlist] \
         -width 20
        
    # save all settings button
    ttk::button $::midiWin.saveall -text "Save All Settings"  -width -1\
        -command "::dialog_midi::apply $mytoplevel; pdsend \"pd save-preferences\"" 
    # buttons
    ttk::frame $::midiWin.buttonframe 
    ttk::button $::midiWin.buttonframe.cancel -text "Cancel" \
        -command "::dialog_midi::cancel $mytoplevel"
    ttk::button $::midiWin.buttonframe.apply -text "Apply" \
        -command "::dialog_midi::apply $mytoplevel"
    ttk::button $::midiWin.buttonframe.ok -text "OK" \
        -command "::dialog_midi::ok $mytoplevel" -default active

# Layout 
    grid $::midiWin -column 0 -row 0 -sticky nwes
    grid $::midiWin.inputs -column 0 -row 0 -sticky nwes -pady 2

    grid $::midiWin.inputs.in1Label -column 0 -row 0
    grid $::midiWin.inputs.in1Select -column 1 -row 0
    grid $::midiWin.inputs.in2Label -column 0 -row 1
    grid $::midiWin.inputs.in2Select -column 1 -row 1
    grid $::midiWin.inputs.in3Label -column 0 -row 2
    grid $::midiWin.inputs.in3Select -column 1 -row 2
    grid $::midiWin.inputs.in4Label -column 0 -row 3
    grid $::midiWin.inputs.in4Select -column 1 -row 3

    grid $::midiWin.inputs.in5Label -column 2 -row 0 -padx 2
    grid $::midiWin.inputs.in5Select -column 3 -row 0 -pady 1
    grid $::midiWin.inputs.in6Label -column 2 -row 1 -padx 2
    grid $::midiWin.inputs.in6Select -column 3 -row 1 -pady 1
    grid $::midiWin.inputs.in7Label -column 2 -row 2 -padx 2
    grid $::midiWin.inputs.in7Select -column 3 -row 2 -pady 1
    grid $::midiWin.inputs.in8Label -column 2 -row 3 -padx 2
    grid $::midiWin.inputs.in8Select -column 3 -row 3 -pady 1

    grid $::midiWin.outputs -column 0 -row 1 -sticky nwes -pady 2
 
    grid $::midiWin.outputs.out1Label -column 0 -row 0
    grid $::midiWin.outputs.out1Select -column 1 -row 0
    grid $::midiWin.outputs.out2Label -column 0 -row 1
    grid $::midiWin.outputs.out2Select -column 1 -row 1
    grid $::midiWin.outputs.out3Label -column 0 -row 2
    grid $::midiWin.outputs.out3Select -column 1 -row 2
    grid $::midiWin.outputs.out4Label -column 0 -row 3
    grid $::midiWin.outputs.out4Select -column 1 -row 3

    grid $::midiWin.outputs.out5Label -column 2 -row 0 -padx 2
    grid $::midiWin.outputs.out5Select -column 3 -row 0 -pady 1
    grid $::midiWin.outputs.out6Label -column 2 -row 1 -padx 2
    grid $::midiWin.outputs.out6Select -column 3 -row 1 -pady 1
    grid $::midiWin.outputs.out7Label -column 2 -row 2 -padx 2
    grid $::midiWin.outputs.out7Select -column 3 -row 2 -pady 1
    grid $::midiWin.outputs.out8Label -column 2 -row 3 -padx 2
    grid $::midiWin.outputs.out8Select -column 3 -row 3 -pady 1

    grid $::midiWin.saveall -column 0 -row 2 -pady 2
    grid $::midiWin.buttonframe -column 0 -row 3 -pady 2
    grid $::midiWin.buttonframe.cancel -column 0 -row 0
    grid $::midiWin.buttonframe.apply -column 1 -row 0 -padx 2
    grid $::midiWin.buttonframe.ok -column 2 -row 0

    # set focus
    focus $::midiWin.buttonframe.ok

    # for focus handling on OSX
    if {$::windowingsystem eq "aqua"} {

        # remove cancel button from focus list since it's not activated on Return
        $::midiWin.buttonframe.cancel config -takefocus 0

        # show active focus on multiple device button
        if {[winfo exists $::midiWin.longbutton.b]} {
            bind $::midiWin.longbutton.b <KeyPress-Return> "$::midiWin.longbutton.b invoke"
            bind $::midiWin.longbutton.b <FocusIn> "::dialog_midi::unbind_return $mytoplevel; $::midiWin.longbutton.b config -default active"
            bind $::midiWin.longbutton.b <FocusOut> "::dialog_midi::rebind_return $mytoplevel; $::midiWin.longbutton.b config -default normal"
        }

        # show active focus on save settings button
        bind $::midiWin.saveall <KeyPress-Return> "$::midiWin.saveall invoke"
        bind $::midiWin.saveall <FocusIn> "::dialog_midi::unbind_return $mytoplevel; $::midiWin.saveall config -default active"
        bind $::midiWin.saveall <FocusOut> "::dialog_midi::rebind_return $mytoplevel; $::midiWin.saveall config -default normal"

        # show active focus on the ok button as it *is* activated on Return
        $::midiWin.buttonframe.ok config -default normal
        bind $::midiWin.buttonframe.ok <FocusIn> "$::midiWin.buttonframe.ok config -default active"
        bind $::midiWin.buttonframe.ok <FocusOut> "$::midiWin.buttonframe.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        # if {[winfo exists $::midiWin.longbutton.b]} {
        #     $::midiWin.longbutton.b config -highlightthickness 0
        # }
        # $::midiWin.saveall config -highlightthickness 0
        # $::midiWin.buttonframe.ok config -highlightthickness 0
        # $::midiWin.buttonframe.cancel config -highlightthickness 0
    }

    # set min size based on widget sizing & pos over pdwindow
    wm minsize $mytoplevel [winfo reqwidth $mytoplevel] [winfo reqheight $mytoplevel]
    position_over_window $mytoplevel .pdwindow
    raise $mytoplevel
}

# Leaving this alone for now, but if someone asks I'll probably change it
proc ::dialog_midi::pdtk_alsa_midi_dialog {id indev1 indev2 indev3 indev4 \
        outdev1 outdev2 outdev3 outdev4 longform alsa} {

    global midi_indev1 midi_indev2 midi_indev3 midi_indev4 midi_indev5 \
         midi_indev6 midi_indev7 midi_indev8 midi_indev9
    global midi_outdev1 midi_outdev2 midi_outdev3 midi_outdev4 midi_outdev5 \
         midi_outdev6 midi_outdev7 midi_outdev8 midi_outdev9
    global midi_indevlist midi_outdevlist
    global midi_alsain midi_alsaout

    set midi_indev1 $indev1
    set midi_indev2 $indev2
    set midi_indev3 $indev3
    set midi_indev4 $indev4
    set midi_indev5 0
    set midi_indev6 0
    set midi_indev7 0
    set midi_indev8 0
    set midi_indev9 0
    set midi_outdev1 $outdev1
    set midi_outdev2 $outdev2
    set midi_outdev3 $outdev3
    set midi_outdev4 $outdev4
    set midi_outdev5 0
    set midi_outdev6 0
    set midi_outdev7 0
    set midi_outdev8 0
    set midi_outdev9 0
    set midi_alsain [expr [llength $midi_indevlist] - 1]
    set midi_alsaout [expr [llength $midi_outdevlist] - 1]

    toplevel $mytoplevel -class DialogWindow
    wm withdraw $mytoplevel
    wm title $mytoplevel [_ "ALSA MIDI Settings"]
    wm resizable $mytoplevel 0 0
    wm transient $mytoplevel
    $mytoplevel configure -padx 10 -pady 5
    if {$::windowingsystem eq "aqua"} {$mytoplevel configure -menu .menubar}
    ::pd_bindings::dialog_bindings $mytoplevel "midi"

    frame $mytoplevel.in1f
    pack $mytoplevel.in1f -side top

    if {$alsa} {
        label $mytoplevel.in1f.l1 -text [_ "In Ports:"]
        entry $mytoplevel.in1f.x1 -textvariable midi_alsain -width 4
        pack $mytoplevel.in1f.l1 $mytoplevel.in1f.x1 -side left
        label $mytoplevel.in1f.l2 -text [_ "Out Ports:"]
        entry $mytoplevel.in1f.x2 -textvariable midi_alsaout -width 4
        pack $mytoplevel.in1f.l2 $mytoplevel.in1f.x2 -side left
    }

    # save all settings button
    button $mytoplevel.saveall -text [_ "Save All Settings"] \
        -command "::dialog_midi::apply $mytoplevel; pdsend \"pd save-preferences\""
    pack $mytoplevel.saveall -side top -expand 1 -ipadx 10 -pady 5

    # buttons
    frame $mytoplevel.buttonframe
    pack $mytoplevel.buttonframe -side top -after $mytoplevel.saveall -pady 2m
    button $mytoplevel.buttonframe.cancel -text [_ "Cancel"]\
        -command "::dialog_midi::cancel $mytoplevel"
    button $mytoplevel.buttonframe.apply -text [_ "Apply"]\
        -command "::dialog_midi::apply $mytoplevel"
    button $mytoplevel.buttonframe.ok -text [_ "OK"]\
        -command "::dialog_midi::ok $mytoplevel" -default active
    pack $mytoplevel.buttonframe.cancel -side left -expand 1 -fill x -padx 15 -ipadx 10
    pack $mytoplevel.buttonframe.apply -side left -expand 1 -fill x -padx 15 -ipadx 10
    pack $mytoplevel.buttonframe.ok -side left -expand 1 -fill x -padx 15 -ipadx 10

    # set min size based on widget sizing & pos over pdwindow
    wm minsize $mytoplevel [winfo reqwidth $mytoplevel] [winfo reqheight $mytoplevel]
    position_over_window $mytoplevel .pdwindow
    raise "$mytoplevel"
}

# for focus handling on OSX
proc ::dialog_midi::rebind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> "::dialog_midi::ok $mytoplevel"
    focus $mytoplevel.buttonframe.ok
    return 0
}

# for focus handling on OSX
proc ::dialog_midi::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> break
    return 1
}
