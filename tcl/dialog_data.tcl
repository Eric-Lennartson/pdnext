
package provide dialog_data 0.1

namespace eval ::dialog_data:: {
    namespace export pdtk_data_dialog
}

############ pdtk_data_dialog -- run a data dialog #########

proc ::dialog_data::send {mytoplevel} {
    for {set i 1} {[$mytoplevel.win.text compare [concat $i.0 + 3 chars] < end]} \
        {incr i 1} {
            pdsend "$mytoplevel data [$mytoplevel.win.text get $i.0 [expr $i + 1].0]"
        }
    pdsend "$mytoplevel end"
}

proc ::dialog_data::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

proc ::dialog_data::ok {mytoplevel} {
    ::dialog_data::send $mytoplevel
    ::dialog_data::cancel $mytoplevel
}

proc ::dialog_data::pdtk_data_dialog {mytoplevel stuff} {
    variable modifier
    set modkeyname "Ctrl"
    if {$::windowingsystem eq "aqua"} {
        set modkeyname "Cmd"
    }

    toplevel $mytoplevel
    wm title $mytoplevel "Data Properties"
    wm group $mytoplevel $::focused_window
    wm transient $mytoplevel $::focused_window
    $mytoplevel configure -menu $::dialog_menubar
    $mytoplevel configure -padx 0 -pady 0

    ttk::frame $mytoplevel.win -padding 5

    text $mytoplevel.win.text -relief raised -wrap word -highlightthickness 0 -bd 0 -height 40 -width 60 \
        -yscrollcommand "$mytoplevel.win.scroll set" -background "#3c3836" -foreground "#c5b18d" \
        -highlightbackground "#3c3836" -highlightcolor "#3c3836" -insertbackground "white" \
        -selectbackground "#7c6f64" -selectforeground "#7daea3"

    ttk::scrollbar $mytoplevel.win.scroll -command "$mytoplevel.win.text yview"

    ttk::frame $mytoplevel.win.buttonframe
    ttk::button $mytoplevel.win.buttonframe.send -text "Send ($modkeyname-S)" \
        -command "::dialog_data::send $mytoplevel" -width 12 
    ttk::button $mytoplevel.win.buttonframe.ok -text "Done ($modkeyname-D)" \
        -command "::dialog_data::ok $mytoplevel" -width 12 

    grid $mytoplevel.win -column 0 -row 0
    grid $mytoplevel.win.text -column 0 -row 0
    grid $mytoplevel.win.scroll -column 1 -row 0 -sticky ns

    grid $mytoplevel.win.buttonframe -column 0 -row 1 -pady 2
    grid $mytoplevel.win.buttonframe.send -column 0 -row 0
    grid $mytoplevel.win.buttonframe.ok   -column 1 -row 0

    $mytoplevel.win.text insert end $stuff
    bind $mytoplevel.win.text <$::modifier-Key-s> "::dialog_data::send $mytoplevel"
    bind $mytoplevel.win.text <$::modifier-Key-d> "::dialog_data::ok $mytoplevel"
    bind $mytoplevel.win.text <$::modifier-Key-w> "::dialog_data::cancel $mytoplevel"
    focus $mytoplevel.win.text

    position_over_window $mytoplevel $::focused_window
}
