package provide dialog_audio 0.1

namespace eval ::dialog_audio:: {
    namespace export pdtk_audio_dialog
}

# TODO this panel really needs some reworking, it works but the code is very
# unreadable.  The panel could look a lot better too, like using menubuttons
# instead of regular buttons with tk_popup for pulldown menus.

# There is support for multiple devices but tbh, I have never seen it...

####################### audio dialog ##################3

proc ::dialog_audio::apply {mytoplevel} {
    global audio_indev1 audio_indev2 audio_indev3 audio_indev4
    global audio_inchan1 audio_inchan2 audio_inchan3 audio_inchan4
    global audio_inenable1 audio_inenable2 audio_inenable3 audio_inenable4
    global audio_outdev1 audio_outdev2 audio_outdev3 audio_outdev4
    global audio_outchan1 audio_outchan2 audio_outchan3 audio_outchan4
    global audio_outenable1 audio_outenable2 audio_outenable3 audio_outenable4
    global audio_sr audio_advance audio_callback audio_blocksize

    pdsend "pd audio-dialog \
        $audio_indev1 \
        $audio_indev2 \
        $audio_indev3 \
        $audio_indev4 \
        [expr $audio_inchan1 * ( $audio_inenable1 ? 1 : -1 ) ]\
        [expr $audio_inchan2 * ( $audio_inenable2 ? 1 : -1 ) ]\
        [expr $audio_inchan3 * ( $audio_inenable3 ? 1 : -1 ) ]\
        [expr $audio_inchan4 * ( $audio_inenable4 ? 1 : -1 ) ]\
        $audio_outdev1 \
        $audio_outdev2 \
        $audio_outdev3 \
        $audio_outdev4 \
        [expr $audio_outchan1 * ( $audio_outenable1 ? 1 : -1 ) ]\
        [expr $audio_outchan2 * ( $audio_outenable2 ? 1 : -1 ) ]\
        [expr $audio_outchan3 * ( $audio_outenable3 ? 1 : -1 ) ]\
        [expr $audio_outchan4 * ( $audio_outenable4 ? 1 : -1 ) ]\
        $audio_sr \
        $audio_advance \
        $audio_callback \
        $audio_blocksize"
}

proc ::dialog_audio::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

proc ::dialog_audio::ok {mytoplevel} {
    ::dialog_audio::apply $mytoplevel
    ::dialog_audio::cancel $mytoplevel
}

# callback from popup menu
proc audio_popup_action {buttonname varname devlist index} {
    global audio_indevlist audio_outdevlist $varname
    $buttonname configure -text [lindex $devlist $index]
    set $varname $index
}

# create a popup menu
proc audio_popup {name buttonname varname devlist} {
    if [winfo exists $name.popup] {destroy $name.popup}
    menu $name.popup -tearoff false
    if {$::windowingsystem eq "win32"} {
        $name.popup configure -font menuFont
    }
    for {set x 0} {$x<[llength $devlist]} {incr x} {
        $name.popup add command -label [lindex $devlist $x] \
            -command [list audio_popup_action \
                          $buttonname $varname $devlist $x]
    }
    # open popup over source button
    set x [expr [winfo rootx $buttonname] + ( [winfo width $buttonname] / 2 )]
    set y [expr [winfo rooty $buttonname] + ( [winfo height $buttonname] / 2 )]
    tk_popup $name.popup $x $y 0
}

# start a dialog window to select audio devices and settings.  "multi"
# is 0 if only one device is allowed; 1 if one apiece may be specified for
# input and output; and 2 if we can select multiple devices.  "longform"
# (which only makes sense if "multi" is 2) asks us to make controls for
# opening several devices; if not, we get an extra button to turn longform
# on and restart the dialog.

proc ::dialog_audio::pdtk_audio_dialog {mytoplevel \
        indev1 indev2 indev3 indev4 \
        inchan1 inchan2 inchan3 inchan4 \
        outdev1 outdev2 outdev3 outdev4 \
        outchan1 outchan2 outchan3 outchan4 sr advance multi callback \
        longform blocksize} {
    global audio_indev1 audio_indev2 audio_indev3 audio_indev4
    global audio_inchan1 audio_inchan2 audio_inchan3 audio_inchan4
    global audio_inenable1 audio_inenable2 audio_inenable3 audio_inenable4
    global audio_outdev1 audio_outdev2 audio_outdev3 audio_outdev4
    global audio_outchan1 audio_outchan2 audio_outchan3 audio_outchan4
    global audio_outenable1 audio_outenable2 audio_outenable3 audio_outenable4
    global audio_sr audio_advance audio_callback audio_blocksize
    global audio_indevlist audio_outdevlist
    global pd_indev pd_outdev
    global audio_longform

    set audio_indev1 $indev1
    set audio_indev2 $indev2
    set audio_indev3 $indev3
    set audio_indev4 $indev4

    set audio_inchan1 [expr ( $inchan1 > 0 ? $inchan1 : -$inchan1 ) ]
    set audio_inenable1 [expr $inchan1 > 0 ]
    set audio_inchan2 [expr ( $inchan2 > 0 ? $inchan2 : -$inchan2 ) ]
    set audio_inenable2 [expr $inchan2 > 0 ]
    set audio_inchan3 [expr ( $inchan3 > 0 ? $inchan3 : -$inchan3 ) ]
    set audio_inenable3 [expr $inchan3 > 0 ]
    set audio_inchan4 [expr ( $inchan4 > 0 ? $inchan4 : -$inchan4 ) ]
    set audio_inenable4 [expr $inchan4 > 0 ]

    set audio_outdev1 $outdev1
    set audio_outdev2 $outdev2
    set audio_outdev3 $outdev3
    set audio_outdev4 $outdev4

    set audio_outchan1 [expr ( $outchan1 > 0 ? $outchan1 : -$outchan1 ) ]
    set audio_outenable1 [expr $outchan1 > 0 ]
    set audio_outchan2 [expr ( $outchan2 > 0 ? $outchan2 : -$outchan2 ) ]
    set audio_outenable2 [expr $outchan2 > 0 ]
    set audio_outchan3 [expr ( $outchan3 > 0 ? $outchan3 : -$outchan3 ) ]
    set audio_outenable3 [expr $outchan3 > 0 ]
    set audio_outchan4 [expr ( $outchan4 > 0 ? $outchan4 : -$outchan4 ) ]
    set audio_outenable4 [expr $outchan4 > 0 ]

    set audio_sr $sr
    set audio_advance $advance
    set audio_callback $callback
    set audio_blocksize $blocksize

    toplevel $mytoplevel
    wm withdraw $mytoplevel
    wm title $mytoplevel "Audio Settings"
    wm group $mytoplevel .
    wm resizable $mytoplevel 0 0
    wm transient $mytoplevel
    wm minsize $mytoplevel 380 320
    $mytoplevel configure -menu $::dialog_menubar
    ::pd_bindings::dialog_bindings $mytoplevel "audio"

    ttk::frame $mytoplevel.w -padding 5 
    set ::audioWin $mytoplevel.w

# Settings Widgets
    ttk::labelframe $::audioWin.settings -text " Settings " -padding "3 2 3 3" 
    
    ttk::label $::audioWin.settings.sampleRateLabel -text "Sample rate:" 
    ttk::combobox $::audioWin.settings.sampleRate -textvariable audio_sr -width 8 \
        -values {44100 48000 882000 96000 176000 192000} 
    bind $::audioWin.settings.sampleRate <<ComboboxSelected>> { 
        $::audioWin.settings.sampleRate selection clear
    }

    ttk::label $::audioWin.settings.delayLabel -text "Delay (msec):" 
    ttk::entry $::audioWin.settings.delay -textvariable audio_advance -width 4 

    ttk::label $::audioWin.settings.blockSizeLabel -text "Block size:" 
    ttk::combobox $::audioWin.settings.blockSize -textvariable audio_blocksize -width 4 \
        -values {64 128 256 512 1024 2048} 
    bind $::audioWin.settings.blockSize <<ComboboxSelected>> { 
        $::audioWin.settings.blockSize selection clear
    }

# Callbacks (removed from current pd version)
    # if {$audio_callback >= 0} {
    #     frame $mytoplevel.settings.callback
    #     pack $mytoplevel.settings.callback -side bottom -fill x
    #     checkbutton $mytoplevel.settings.callback.c_button -variable audio_callback \
    #         -text [_ "Use callbacks"]
    #     pack $mytoplevel.settings.callback.c_button -side right
    # }

# Input Widgets
    ttk::labelframe $::audioWin.inputs -text " Input " -padding "3 2 3 3" 

    # input device 1
    ttk::checkbutton $::audioWin.inputs.enableInput -variable audio_inenable1 \
         ;#-text "1:"
    ttk::button $::audioWin.inputs.inputSelect -text [lindex $audio_indevlist $audio_indev1] \
        -command [list audio_popup $mytoplevel $::audioWin.inputs.inputSelect audio_indev1 $audio_indevlist] \
        -width 18 
    ttk::label $::audioWin.inputs.numChannelsLabel -text "Channels:" 
    ttk::entry $::audioWin.inputs.numChannels -textvariable audio_inchan1 -width 3 

# Multi Input Code (inactive for now)
    # input device 2
    # if {$longform && $multi > 1 && [llength $audio_indevlist] > 1} {
    #     frame $mytoplevel.inputs.in2f
    #     pack $mytoplevel.inputs.in2f -side top

    #     checkbutton $mytoplevel.inputs.in2f.x0 -variable audio_inenable2 \
    #         -text "2:" -anchor e
    #     button $mytoplevel.inputs.in2f.x1 -text [lindex $audio_indevlist $audio_indev2] \
    #         -command [list audio_popup $mytoplevel $mytoplevel.inputs.in2f.x1 audio_indev2 \
    #             $audio_indevlist]
    #     label $mytoplevel.inputs.in2f.l2 -text [_ "Channels:"]
    #     entry $mytoplevel.inputs.in2f.x2 -textvariable audio_inchan2 -width 3
    #     pack $mytoplevel.inputs.in2f.x0 -side left
    #     pack $mytoplevel.inputs.in2f.x1 -side left -fill x -expand 1
    #     pack $mytoplevel.inputs.in2f.x2 $mytoplevel.inputs.in2f.l2 -side right
    # }

    # # input device 3
    # if {$longform && $multi > 1 && [llength $audio_indevlist] > 2} {
    #     frame $mytoplevel.inputs.in3f
    #     pack $mytoplevel.inputs.in3f -side top

    #     checkbutton $mytoplevel.inputs.in3f.x0 -variable audio_inenable3 \
    #         -text "3:" -anchor e
    #     button $mytoplevel.inputs.in3f.x1 -text [lindex $audio_indevlist $audio_indev3] \
    #         -command [list audio_popup $mytoplevel $mytoplevel.inputs.in3f.x1 audio_indev3 \
    #             $audio_indevlist]
    #     label $mytoplevel.inputs.in3f.l2 -text [_ "Channels:"]
    #     entry $mytoplevel.inputs.in3f.x2 -textvariable audio_inchan3 -width 3
    #     pack $mytoplevel.inputs.in3f.x0 -side left
    #     pack $mytoplevel.inputs.in3f.x1 -side left -fill x -expand 1
    #     pack $mytoplevel.inputs.in3f.x2 $mytoplevel.inputs.in3f.l2 -side right
    # }

    # # input device 4
    # if {$longform && $multi > 1 && [llength $audio_indevlist] > 3} {
    #     frame $mytoplevel.inputs.in4f
    #     pack $mytoplevel.inputs.in4f -side top

    #     checkbutton $mytoplevel.inputs.in4f.x0 -variable audio_inenable4 \
    #         -text "4:" -anchor e
    #     button $mytoplevel.inputs.in4f.x1 -text [lindex $audio_indevlist $audio_indev4] \
    #         -command [list audio_popup $mytoplevel $mytoplevel.inputs.in4f.x1 audio_indev4 \
    #             $audio_indevlist]
    #     label $mytoplevel.inputs.in4f.l2 -text [_ "Channels:"]
    #     entry $mytoplevel.inputs.in4f.x2 -textvariable audio_inchan4 -width 3
    #     pack $mytoplevel.inputs.in4f.x0 -side left
    #     pack $mytoplevel.inputs.in4f.x1 -side left -fill x -expand 1
    #     pack $mytoplevel.inputs.in4f.x2 $mytoplevel.inputs.in4f.l2 -side right
    # }

# Output Widgets
    ttk::labelframe $::audioWin.outputs -text " Output " -padding "3 2 3 3" 

    # output device 1
    ttk::checkbutton $::audioWin.outputs.enableOutput -variable audio_outenable1 \
         ;#-text "1:"
    # if {$multi == 0} {
    #     label $mytoplevel.outputs.out1f.l1 \
    #         -text [_ "(same as input device)..."]
    # } else {
        ttk::button $::audioWin.outputs.outputSelect -text [lindex $audio_outdevlist $audio_outdev1] \
            -command  [list audio_popup $mytoplevel $::audioWin.outputs.outputSelect audio_outdev1 $audio_outdevlist] \
            -width 18 
    # }
    ttk::label $::audioWin.outputs.numChannelsLabel -text "Channels:" 
    ttk::entry $::audioWin.outputs.numChannels -textvariable audio_outchan1 -width 3 

# Multi Output Code (inactive for now)
    # if {$multi == 0} {
    #     pack $mytoplevel.outputs.enableOutput $mytoplevel.outputs.out1f.l1 -side left
    #     pack $mytoplevel.outputs.numChannels -side right
    # } else { These have been moved elsewhere but stay here in case I fuck up
        # pack $mytoplevel.outputs.enableOutput -side left
        # pack $mytoplevel.outputs.outputSelect -side left -fill x -expand 1
        # pack $mytoplevel.outputs.numChannels $mytoplevel.outputs.numChannelsLabel -side right
    # }

    # output device 2
    # if {$longform && $multi > 1 && [llength $audio_outdevlist] > 1} {
    #     frame $mytoplevel.outputs.out2f
    #     pack $mytoplevel.outputs.out2f -side top

    #     checkbutton $mytoplevel.outputs.out2f.x0 -variable audio_outenable2 \
    #         -text "2:" -anchor e
    #     button $mytoplevel.outputs.out2f.x1 -text [lindex $audio_outdevlist $audio_outdev2] \
    #         -command \
    #         [list audio_popup $mytoplevel $mytoplevel.outputs.out2f.x1 audio_outdev2 $audio_outdevlist]
    #     label $mytoplevel.outputs.out2f.l2 -text [_ "Channels:"]
    #     entry $mytoplevel.outputs.out2f.x2 -textvariable audio_outchan2 -width 3
    #     pack $mytoplevel.outputs.out2f.x0 -side left
    #     pack $mytoplevel.outputs.out2f.x1 -side left -fill x -expand 1
    #     pack $mytoplevel.outputs.out2f.x2 $mytoplevel.outputs.out2f.l2 -side right
    # }

    # # output device 3
    # if {$longform && $multi > 1 && [llength $audio_outdevlist] > 2} {
    #     frame $mytoplevel.outputs.out3f
    #     pack $mytoplevel.outputs.out3f -side top

    #     checkbutton $mytoplevel.outputs.out3f.x0 -variable audio_outenable3 \
    #         -text "3:" -anchor e
    #     button $mytoplevel.outputs.out3f.x1 -text [lindex $audio_outdevlist $audio_outdev3] \
    #         -command \
    #         [list audio_popup $mytoplevel $mytoplevel.outputs.out3f.x1 audio_outdev3 $audio_outdevlist]
    #     label $mytoplevel.outputs.out3f.l2 -text [_ "Channels:"]
    #     entry $mytoplevel.outputs.out3f.x2 -textvariable audio_outchan3 -width 3
    #     pack $mytoplevel.outputs.out3f.x0 -side left
    #     pack $mytoplevel.outputs.out3f.x1 -side left -fill x -expand 1
    #     pack $mytoplevel.outputs.out3f.x2 $mytoplevel.outputs.out3f.l2 -side right
    # }

    # # output device 4
    # if {$longform && $multi > 1 && [llength $audio_outdevlist] > 3} {
    #     frame $mytoplevel.outputs.out4f
    #     pack $mytoplevel.outputs.out4f -side top

    #     checkbutton $mytoplevel.outputs.out4f.x0 -variable audio_outenable4 \
    #         -text "4:" -anchor e
    #     button $mytoplevel.outputs.out4f.x1 -text [lindex $audio_outdevlist $audio_outdev4] \
    #         -command \
    #         [list audio_popup $mytoplevel $mytoplevel.outputs.out4f.x1 audio_outdev4 $audio_outdevlist]
    #     label $mytoplevel.outputs.out4f.l2 -text [_ "Channels:"]
    #     entry $mytoplevel.outputs.out4f.x2 -textvariable audio_outchan4 -width 3
    #     pack $mytoplevel.outputs.out4f.x0 -side left
    #     pack $mytoplevel.outputs.out4f.x1 -side left -fill x -expand 1
    #     pack $mytoplevel.outputs.out4f.x2 $mytoplevel.outputs.out4f.l2 -side right
    # }

    # # If not the "long form" but if "multi" is 2, make a button to
    # # restart with longform set.
    # if {$longform == 0 && $multi > 1} {
    #     frame $mytoplevel.longbutton
    #     pack $mytoplevel.longbutton -side top -fill x
    #     button $mytoplevel.longbutton.b -text [_ "Use Multiple Devices"] \
    #         -command  {pdsend "pd audio-properties 1"}
    #     pack $mytoplevel.longbutton.b -expand 1 -ipadx 10 -pady 5
    # }

# Button Widgets
    ttk::button $::audioWin.saveall -text "Save All Settings" -width -1 \
        -command "::dialog_audio::apply $mytoplevel; pdsend \"pd save-preferences\"" \
        

    ttk::frame $::audioWin.buttonframe 
    ttk::button $::audioWin.buttonframe.cancel -text "Cancel" \
        -command "::dialog_audio::cancel $mytoplevel" \
        
    ttk::button $::audioWin.buttonframe.apply -text "Apply" \
        -command "::dialog_audio::apply $mytoplevel" \
        
    ttk::button $::audioWin.buttonframe.ok -text "OK" \
        -command "::dialog_audio::ok $mytoplevel" -default active \
        

# Layout
    grid $::audioWin -column 0 -row 0 -sticky nwes

    grid $::audioWin.settings -column 0 -row 0 -sticky nwes
    grid $::audioWin.settings.sampleRateLabel -column 0 -row 0 -sticky w
    grid $::audioWin.settings.sampleRate  -column 1 -row 0 -sticky w
    grid $::audioWin.settings.delayLabel -column 0 -row 1 -sticky w
    grid $::audioWin.settings.delay -column 1 -row 1 -sticky w -pady 4
    grid $::audioWin.settings.blockSizeLabel -column 0 -row 2 -sticky w
    grid $::audioWin.settings.blockSize -column 1 -row 2 -sticky w

    grid $::audioWin.inputs -column 0 -row 1 -sticky nwes -pady 2
    grid $::audioWin.inputs.enableInput -column 0 -row 0
    grid $::audioWin.inputs.inputSelect -column 1 -row 0
    grid $::audioWin.inputs.numChannelsLabel -column 2 -row 0
    grid $::audioWin.inputs.numChannels -column 3 -row 0

    grid $::audioWin.outputs -column 0 -row 2 -sticky nwes -pady 2
    grid $::audioWin.outputs.enableOutput -column 0 -row 0
    grid $::audioWin.outputs.outputSelect -column 1 -row 0
    grid $::audioWin.outputs.numChannelsLabel -column 2 -row 0
    grid $::audioWin.outputs.numChannels -column 3 -row 0

    grid $::audioWin.saveall -column 0 -row 3 -pady 2

    grid $::audioWin.buttonframe -column 0 -row 4 -pady 2
    grid $::audioWin.buttonframe.ok     -column 0 -row 0
    grid $::audioWin.buttonframe.apply  -column 1 -row 0
    grid $::audioWin.buttonframe.cancel -column 2 -row 0

    # set focus
    focus $::audioWin.settings.sampleRate

# for focus handling on OSX
    if {$::windowingsystem eq "aqua"} {

        # call apply on Return in entry boxes that are in focus & rebind Return to ok button
        bind $::audioWin.settings.sampleRate <KeyPress-Return> "::dialog_audio::rebind_return $mytoplevel"
        bind $::audioWin.settings.delay <KeyPress-Return> "::dialog_audio::rebind_return $mytoplevel"
        bind $::audioWin.outputs.numChannels <KeyPress-Return> "::dialog_audio::rebind_return $mytoplevel"

        # unbind Return from ok button when an entry takes focus
        $::audioWin.settings.sampleRate config -validate focusin -validatecommand "::dialog_audio::unbind_return $mytoplevel"
        $::audioWin.settings.delay config -validate focusin -validatecommand "::dialog_audio::unbind_return $mytoplevel"
        $::audioWin.outputs.numChannels config -validate focusin -validatecommand "::dialog_audio::unbind_return $mytoplevel"

        # remove cancel button from focus list since it's not activated on Return
        $::audioWin.buttonframe.cancel config -takefocus 0

        # show active focus on multiple device button
        if {[winfo exists $::audioWin.longbutton.b]} {
            bind $::audioWin.longbutton.b <KeyPress-Return> "$::audioWin.longbutton.b invoke"
            bind $::audioWin.longbutton.b <FocusIn> "::dialog_audio::unbind_return $mytoplevel; $::audioWin.longbutton.b config -default active"
            bind $::audioWin.longbutton.b <FocusOut> "::dialog_audio::rebind_return $mytoplevel; $::audioWin.longbutton.b config -default normal"
        }

        # show active focus on save settings button
        bind $::audioWin.saveall <KeyPress-Return> "$::audioWin.saveall invoke"
        bind $::audioWin.saveall <FocusIn> "::dialog_audio::unbind_return $mytoplevel; $::audioWin.saveall config -default active"
        bind $::audioWin.saveall <FocusOut> "::dialog_audio::rebind_return $mytoplevel; $::audioWin.saveall config -default normal"

        # show active focus on the ok button as it *is* activated on Return
        $::audioWin.buttonframe.ok config -default normal
        bind $::audioWin.buttonframe.ok <FocusIn> "$::audioWin.buttonframe.ok config -default active"
        bind $::audioWin.buttonframe.ok <FocusOut> "$::audioWin.buttonframe.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        # if {[winfo exists $mytoplevel.longbutton.b]} {
        #     $mytoplevel.longbutton.b config -highlightthickness 0
        # }
        # $mytoplevel.saveall config -highlightthickness 0
        # $mytoplevel.buttonframe.ok config -highlightthickness 0
        # $mytoplevel.buttonframe.cancel config -highlightthickness 0
    }

    # set min size based on widget sizing & pos over pdwindow
    wm minsize $mytoplevel [winfo reqwidth $mytoplevel] [winfo reqheight $mytoplevel]
    position_over_window $mytoplevel .pdwindow
    raise $mytoplevel
}

# for focus handling on OSX
proc ::dialog_audio::rebind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> "::dialog_audio::ok $mytoplevel"
    focus $::audioWin.buttonframe.ok
    return 0
}

# for focus handling on OSX
proc ::dialog_audio::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> break
    return 1
}
