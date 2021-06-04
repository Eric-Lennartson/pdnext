
package provide dialog_startup 0.1

package require scrollboxwindow

namespace eval dialog_startup {
    variable defeatrt_flag 0

    namespace export pdtk_startup_dialog
}

########## pdtk_startup_dialog -- dialog window for startup options #########
# Create a simple modal window with an entry widget
# for editing/adding a startup command
# (the next-best-thing to in-place editing)
proc ::dialog_startup::chooseCommand { prompt initialValue } {
    global cmd
    set cmd $initialValue

    toplevel .inputbox
    wm title .inputbox $prompt
    wm group .inputbox .
    wm resizable .inputbox 0 0

    ttk::frame .inputbox.f -padding 5 
    ttk::entry .inputbox.f.entry -width 40 -textvariable cmd 
    bind .inputbox.f.entry <KeyPress-Return> { destroy .inputbox }
    bind .inputbox.f.entry <KeyPress-Escape> { destroy .inputbox }

    ttk::button .inputbox.f.button -width -1 -text [_ "OK"] -command { destroy .inputbox } \
        -width [::msgcat::mcmax [_ "OK"]] 

    grid .inputbox.f -column 0 -row 0
    grid .inputbox.f.entry  -column 0 -row 0
    grid .inputbox.f.button -column 1 -row 0

    raise .inputbox
    focus .inputbox.f.entry
    wm transient .inputbox
    grab .inputbox
    tkwait window .inputbox

    return $cmd
}

proc ::dialog_startup::cancel {mytoplevel} {
    ::scrollboxwindow::cancel $mytoplevel
}

proc ::dialog_startup::ok {mytoplevel} {
    ::scrollboxwindow::ok $mytoplevel dialog_startup::commit
}

proc ::dialog_startup::add {} {
    return [chooseCommand [_ "Add new library"] ""]
}

proc ::dialog_startup::edit { current_library } {
    return [chooseCommand [_ "Edit library"] $current_library]
}

proc ::dialog_startup::commit { new_startup } {
    variable defeatrt_button
    set ::startup_libraries $new_startup
    pdsend "pd startup-dialog $defeatrt_button [pdtk_encodedialog $::startup_flags] [pdtk_encode $::startup_libraries]"
}

# set up the panel with the info from pd
proc ::dialog_startup::pdtk_startup_dialog {mytoplevel defeatrt flags} {
    variable defeatrt_button $defeatrt
    if {$flags ne ""} {variable ::startup_flags [subst -nocommands $flags]}

    if {[winfo exists $mytoplevel]} {
        wm deiconify $mytoplevel
        raise $mytoplevel
        focus $mytoplevel
    } else {
        create_dialog $mytoplevel
    }
}

proc ::dialog_startup::create_dialog {mytoplevel} {
    ::scrollboxwindow::make $mytoplevel $::startup_libraries \
        dialog_startup::add dialog_startup::edit dialog_startup::commit \
        [_ "Startup Libraries"] \
        450 300 0
    wm withdraw $mytoplevel
    ::pd_bindings::dialog_bindings $mytoplevel "startup"

    ttk::frame $mytoplevel.w.flags 
    ttk::label $mytoplevel.w.flags.entryname -text "Startup flags:" 
    ttk::entry $mytoplevel.w.flags.entry -textvariable ::startup_flags -width 40 

    if {$::windowingsystem ne "win32"} {
        ttk::frame $mytoplevel.w.defeatrtframe  
        
        ttk::checkbutton $mytoplevel.w.defeatrtframe.defeatrt \
            -text [_ "Defeat real-time scheduling"] \
            -variable ::dialog_startup::defeatrt_button
    }
    ttk::separator $mytoplevel.w.sep

# Layout
    # listbox widgets (defined in scrollbox.tcl)
    grid $mytoplevel.w -column 0 -row 0
    grid $mytoplevel.w -column 0 -row 0 -stick nwes
    grid $mytoplevel.w.listbox -column 0 -row 0 -sticky nwes
    grid $mytoplevel.w.listbox.box -column 0 -row 0 -sticky nwes
    grid $mytoplevel.w.listbox.scrollbar -column 1 -row 0 -sticky ns

    grid $mytoplevel.w.actions -column 0 -row 1 -sticky w -pady 4
    grid $mytoplevel.w.actions.add_path -column 0 -row 0
    grid $mytoplevel.w.actions.edit_path -column 1 -row 0
    grid $mytoplevel.w.actions.delete_path -column 2 -row 0

    grid $mytoplevel.w.flags -column 0 -row 2 -sticky w -pady 2
    grid $mytoplevel.w.flags.entryname -column 0 -row 0
    grid $mytoplevel.w.flags.entry     -column 1 -row 0
    if {$::windowingsystem ne "win32"} {
        grid $mytoplevel.w.defeatrtframe -column 0 -row 3 -sticky w -pady 2
        grid $mytoplevel.w.defeatrtframe.defeatrt -column 0 -row 0
    }

    grid $mytoplevel.w.sep -column 0 -row 5 -pady 2 -sticky we

    # Buttons (these are defined in scrollboxwindow.tcl)
    grid $mytoplevel.w.buttonframe -column 0 -row 6 -pady 2
    grid $mytoplevel.w.buttonframe.ok -column 0 -row 0
    grid $mytoplevel.w.buttonframe.apply -column 1 -row 0
    grid $mytoplevel.w.buttonframe.cancel -column 2 -row 0

# focus handling on OSX
    if {$::windowingsystem eq "aqua"} {

        # unbind ok button when in listbox
        bind $mytoplevel.w.listbox.box <FocusIn> "::dialog_startup::unbind_return $mytoplevel"
        bind $mytoplevel.w.listbox.box <FocusOut> "::dialog_startup::rebind_return $mytoplevel"

        # call apply on Return in entry boxes that are in focus & rebind Return to ok button
        bind $mytoplevel.w.flags.entry <KeyPress-Return> "::dialog_startup::rebind_return $mytoplevel"

        # unbind Return from ok button when an entry takes focus
        $mytoplevel.w.flags.entry config -validate focusin -validatecommand "::dialog_startup::unbind_return $mytoplevel"

        # remove cancel button from focus list since it's not activated on Return
        $mytoplevel.w.buttonframe.cancel config -takefocus 0

        # show active focus on the ok button as it *is* activated on Return
        $mytoplevel.w.buttonframe.ok config -default normal
        bind $mytoplevel.w.buttonframe.ok <FocusIn> "$mytoplevel.w.buttonframe.ok config -default active"
        bind $mytoplevel.w.buttonframe.ok <FocusOut> "$mytoplevel.w.buttonframe.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        # $mytoplevel.nb.buttonframe.ok config -highlightthickness 0
        # $mytoplevel.nb.buttonframe.cancel config -highlightthickness 0
    }

    # set min size based on widget sizing
    update
    wm minsize $mytoplevel [winfo width $mytoplevel] [winfo reqheight $mytoplevel]

    position_over_window $mytoplevel .pdwindow
    raise $mytoplevel
}

# for focus handling on OSX
proc ::dialog_startup::rebind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Escape> "::dialog_startup::cancel $mytoplevel"
    bind $mytoplevel <KeyPress-Return> "::dialog_startup::ok $mytoplevel"
    focus $mytoplevel.w.buttonframe.ok
    return 0
}

# for focus handling on OSX
proc ::dialog_startup::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Escape> break
    bind $mytoplevel <KeyPress-Return> break
    return 1
}
