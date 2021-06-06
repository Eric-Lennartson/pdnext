package provide dialog_gatom 0.1
package require wheredoesthisgo

namespace eval ::dialog_gatom:: {
    namespace export pdtk_gatom_dialog
}

#maps an style to an action
#the verbose version, when I am hovering over the button, map the color black to the foreground
ttk::style map s.TButton -foreground [list hover "#292828"]

# array for communicating the position of the radiobuttons (Tk's
# radiobutton widget requires this to be global)
# This stores the variable that tells pd where the label goes
array set gatomlabel_radio {}

############ pdtk_gatom_dialog -- run a gatom dialog #########

# manages string bullshit
proc ::dialog_gatom::escape {sym} {
    if {[string length $sym] == 0} {
        set ret "-"
    } else {
        if {[string equal -length 1 $sym "-"]} {
            set ret [string replace $sym 0 0 "--"]
        } else {
            set ret [string map {"$" "#"} $sym]
        }
    }
    return [unspace_text $ret]
}

# manages string bullshit
proc ::dialog_gatom::unescape {sym} {
    if {[string equal -length 1 $sym "-"]} {
        set ret [string replace $sym 0 0 ""]
    } else {
        set ret [string map {"#" "$"} $sym]
    }
    return $ret
}

proc ::dialog_gatom::apply {mytoplevel} {
    global gatomlabel_radio

    pdsend "$mytoplevel param \
        [$::f.settings.widthEntry get] \
        [$::f.settings.minEntry get] \
        [$::f.settings.maxEntry get] \
        [::dialog_gatom::escape [$::f.settings.lblEntry get]] \
        $gatomlabel_radio($mytoplevel) \
        [::dialog_gatom::escape [$::f.settings.rcvEntry get]] \
        [::dialog_gatom::escape [$::f.settings.sndEntry get]]"
}

proc ::dialog_gatom::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

proc ::dialog_gatom::ok {mytoplevel} {
    ::dialog_gatom::apply $mytoplevel
    ::dialog_gatom::cancel $mytoplevel
}

# set up the panel with the info from pd
proc ::dialog_gatom::pdtk_gatom_dialog {mytoplevel initwidth initlower initupper \
                                     initgatomlabel_radio \
                                     initgatomlabel initreceive initsend} {
    global gatomlabel_radio
    set gatomlabel_radio($mytoplevel) $initgatomlabel_radio

    if {[winfo exists $mytoplevel]} {
        wm deiconify $mytoplevel
        raise $mytoplevel
        focus $mytoplevel
    } else {
        create_dialog $mytoplevel
    }

    $::f.settings.widthEntry insert 0 $initwidth
    $::f.settings.minEntry insert 0 $initlower
    $::f.settings.maxEntry insert 0 $initupper
    if {$initgatomlabel ne "-"} {
        $::f.settings.lblEntry insert 0 \
            [::dialog_gatom::unescape $initgatomlabel]
    }
    set gatomlabel_radio($mytoplevel) $initgatomlabel_radio
        if {$initsend ne "-"} {
        $::f.settings.sndEntry insert 0 \
            [::dialog_gatom::unescape $initsend]
    }
    if {$initreceive ne "-"} {
        $::f.settings.rcvEntry insert 0 \
            [::dialog_gatom::unescape $initreceive]
    }
}

proc ::dialog_gatom::create_dialog {mytoplevel} {
    global gatomlabel_radio

    # setting up the toplevel
    toplevel $mytoplevel -class DialogWindow
    wm title $mytoplevel "Atom Box Properties"
    wm group $mytoplevel .
    wm resizable $mytoplevel 0 0
    wm transient $mytoplevel $::focused_window
    $mytoplevel configure -menu $::dialog_menubar
    # $mytoplevel configure -padx 5 -pady 5 -background "#32302f"
    ::pd_bindings::dialog_bindings $mytoplevel "gatom"

    ttk::frame $mytoplevel.frame -padding 5
    set ::f $mytoplevel.frame

    # width widgets
    ttk::labelframe $::f.settings -text " Atom Box "
    ttk::label $::f.settings.widthLabel -text "Width:" 
    ttk::entry $::f.settings.widthEntry -width 6 
    ttk::separator $::f.settings.sep1 -orient "horizontal" 
    # Limits widgets
    ttk::label $::f.settings.minLabel -text "Minimum:" 
    ttk::entry $::f.settings.minEntry -width 6 
    ttk::label $::f.settings.maxLabel -text "Maximum:" 
    ttk::entry $::f.settings.maxEntry -width 6 
    ttk::separator $::f.settings.sep2 -orient "horizontal" 
    # send and recieve widgets
    ttk::label $::f.settings.sndLabel -text "Send symbol:" 
    ttk::entry $::f.settings.sndEntry -width 10 
    ttk::label $::f.settings.rcvLabel -text "Receive symbol:" 
    ttk::entry $::f.settings.rcvEntry -width 10 
    ttk::separator $::f.settings.sep3 -orient "horizontal" 
    # gatom label and position widgets
    ttk::label $::f.settings.gatomLabel -text "Label:" 
    ttk::entry $::f.settings.lblEntry -width 10 
    # ttk::frame $::f.settings.pad 
    ttk::labelframe $::f.settings.position -text " Position " 
    ttk::radiobutton $::f.settings.position.left -value 0 \
        -text "Left" -variable gatomlabel_radio($mytoplevel) 
    ttk::radiobutton $::f.settings.position.right -value 1 \
        -text "Right" -variable gatomlabel_radio($mytoplevel) 
    ttk::radiobutton $::f.settings.position.top -value 2 \
        -text "Top" -variable gatomlabel_radio($mytoplevel) 
    ttk::radiobutton $::f.settings.position.bottom -value 3 \
        -text "Bottom" -variable gatomlabel_radio($mytoplevel) 
    # cancel ok and apply widgets
    ttk::frame $::f.buttonFrame
    ttk::button $::f.buttonFrame.cancel -text "Cancel" \
        -command "::dialog_gatom::cancel $mytoplevel" 
    ttk::button $::f.buttonFrame.apply -text "Apply" \
        -command "::dialog_gatom::apply $mytoplevel" 
    ttk::button $::f.buttonFrame.ok -text "OK" \
        -command "::dialog_gatom::ok $mytoplevel" -default active

    # Layout #######################################################
    grid $::f -column 0 -row 0 -sticky nwes
    grid $::f.settings -column 0 -row 0 -sticky nwes
    # width ########################################################
    grid $::f.settings.widthLabel -column 0 -row 1 -sticky w -padx 10
    grid $::f.settings.widthEntry -column 1 -row 1 -sticky w 
    grid $::f.settings.sep1 -column 0 -row 2 -sticky we -padx 12
    # min/max #####################################################
    grid $::f.settings.minLabel -column 0 -row 3 -sticky w -padx 10
    grid $::f.settings.minEntry -column 1 -row 3 -sticky w
    grid $::f.settings.maxLabel -column 0 -row 4 -sticky w -padx 10
    grid $::f.settings.maxEntry -column 1 -row 4 -sticky w -pady 2
    grid $::f.settings.sep2 -column 0 -row 5 -sticky we -padx 12
    # snd/rcv ######################################################
    grid $::f.settings.sndLabel -column 0 -row 6 -sticky w -padx 10
    grid $::f.settings.sndEntry -column 1 -row 6 -sticky w
    grid $::f.settings.rcvLabel -column 0 -row 7 -sticky w -padx 10
    grid $::f.settings.rcvEntry -column 1 -row 7 -sticky w -pady 2
    grid $::f.settings.sep3 -column 0 -row 8 -sticky we -padx 12
    # gatom label #################################################
    grid $::f.settings.gatomLabel -column 0 -row 9 -sticky w -padx 10
    grid $::f.settings.lblEntry -column 1 -row 9 -sticky w
    # label position ################################################
    grid $::f.settings.position -column 0 -row 10 -columnspan 3 -pady 3 -padx 6
    grid $::f.settings.position.left   -column 0 -row 0 -padx 3 -pady 1
    grid $::f.settings.position.right  -column 1 -row 0 -padx 3 -pady 1
    grid $::f.settings.position.top    -column 2 -row 0 -padx 3 -pady 1
    grid $::f.settings.position.bottom -column 3 -row 0 -padx 3 -pady 1
    # ok/apply/cancel ################################################
    grid $::f.buttonFrame -column 0 -row 1 -pady 1
    grid $::f.buttonFrame.ok -column 0 -row 0 
    grid $::f.buttonFrame.apply -column 1 -row 0 -padx 2
    grid $::f.buttonFrame.cancel -column 2 -row 0

    # live updates on macOS
    if {$::windowingsystem eq "aqua"} {

        # call apply on radiobutton changes
        $::f.settings.position.left config -command [ concat ::dialog_gatom::apply $mytoplevel ]
        $::f.settings.position.right config -command [ concat ::dialog_gatom::apply $mytoplevel ]
        $::f.settings.position.top config -command [ concat ::dialog_gatom::apply $mytoplevel ]
        $::f.settings.position.bottom config -command [ concat ::dialog_gatom::apply $mytoplevel ]

        # allow radiobutton focus
        $::f.settings.position.left config -takefocus 1
        $::f.settings.position.right config -takefocus 1
        $::f.settings.position.top config -takefocus 1
        $::f.settings.position.bottom config -takefocus 1

        # call apply on Return in entry boxes that are in focus & rebind Return to ok button
        bind $::f.settings.widthEntry <KeyPress-Return> "::dialog_gatom::apply_and_rebind_return $mytoplevel"
        bind $::f.settings.minEntry <KeyPress-Return> "::dialog_gatom::apply_and_rebind_return $mytoplevel"
        bind $::f.settings.maxEntry <KeyPress-Return> "::dialog_gatom::apply_and_rebind_return $mytoplevel"
        bind $::f.settings.lblEntry <KeyPress-Return> "::dialog_gatom::apply_and_rebind_return $mytoplevel"
        bind $::f.settings.sndEntry <KeyPress-Return> "::dialog_gatom::apply_and_rebind_return $mytoplevel"
        bind $::f.settings.rcvEntry <KeyPress-Return> "::dialog_gatom::apply_and_rebind_return $mytoplevel"

        # unbind Return from ok button when an entry takes focus
        $::f.settings.widthEntry config -validate focusin -validatecommand "::dialog_gatom::unbind_return $mytoplevel"
        $::f.settings.minEntry config -validate focusin -validatecommand "::dialog_gatom::unbind_return $mytoplevel"
        $::f.settings.maxEntry config -validate focusin -validatecommand "::dialog_gatom::unbind_return $mytoplevel"
        $::f.settings.lblEntry config -validate focusin -validatecommand "::dialog_gatom::unbind_return $mytoplevel"
        $::f.settings.sndEntry config -validate focusin -validatecommand "::dialog_gatom::unbind_return $mytoplevel"
        $::f.settings.rcvEntry config -validate focusin -validatecommand "::dialog_gatom::unbind_return $mytoplevel"

        # remove cancel button from focus list since it's not activated on Return
        $::f.buttonFrame.cancel config -takefocus 0

        # show active focus on the ok button as it *is* activated on Return
        $::f.buttonFrame.ok config -default normal
        bind $::f.buttonFrame.ok <FocusIn> "$::f.buttonFrame.ok config -default active"
        bind $::f.buttonFrame.ok <FocusOut> "$::f.buttonFrame.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        #$::f.buttonFrame.ok config -highlightthickness 0
        #$::f.buttonFrame.cancel config -highlightthickness 0
    }

    position_over_window $mytoplevel $::focused_window
}

# for live widget updates on OSX
proc ::dialog_gatom::apply_and_rebind_return {mytoplevel} {
    ::dialog_gatom::apply $mytoplevel
    bind $mytoplevel <KeyPress-Return> "::dialog_gatom::ok $mytoplevel"
    focus $::f.buttonFrame.ok
    return 0
}

# for live widget updates on OSX
proc ::dialog_gatom::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> break
    return 1
}
