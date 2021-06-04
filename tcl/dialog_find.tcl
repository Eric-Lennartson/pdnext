# the find dialog panel is a bit unusual in that it is created directly by the
# Tcl 'pd-gui'. Most dialog panels are created by sending a message to 'pd',
# which then sends a message to 'pd-gui' to create the panel.

package provide dialog_find 0.1

package require pd_bindings

namespace eval ::dialog_find:: {
    variable find_in_toplevel ".pdwindow"
    # store the state of the "Match whole word only" check box
    variable wholeword_button 0
    # if the search hasn't changed, then the Find button sends "findagain"
    variable previous_wholeword_button 0
    variable previous_findstring ""
    variable find_in_window ""
    variable window_changed 0
    variable find_history {}
    variable history_position 0
    # keep track if we are currently searching
    variable is_searching 0
    variable is_searching_id 0

    namespace export pdtk_showfindresult
}

proc ::dialog_find::get_history {direction} {
    variable find_history
    variable history_position

    incr history_position $direction
    if {$history_position < 0} {set history_position 0}
    if {$history_position > [llength $find_history]} {
        set history_position [llength $find_history]
    }
    .find.win.entry delete 0 end
    .find.win.entry insert 0 [lindex $find_history end-[expr $history_position - 1]]
}

# mytoplevel isn't used here, but is kept for compatibility with other dialog ok procs
proc ::dialog_find::ok {mytoplevel} {
    variable find_in_window
    variable wholeword_button
    variable previous_wholeword_button
    variable previous_findstring
    variable window_changed
    variable find_history
    variable is_searching
    variable is_searching_id

    set findstring [.find.win.entry get]
    if {$findstring eq ""} {
        if {$::windowingsystem eq "aqua"} {bell}
        return
    }
    # start searching
    set $is_searching 1
    if {$find_in_window eq ".pdwindow"} {
        if {$::tcl_version < 8.5} {
            # TODO implement in 8.4 style, without -all
            set matches [.pdwindow.text search -nocase -- $findstring 0.0]
        } else {
            set matches [.pdwindow.text search -all -nocase -- $findstring 0.0]
        }
        .pdwindow.text tag delete sel
        if {[llength $matches] > 0} {
            foreach match $matches {
                .pdwindow.text tag add sel $match "$match wordend"
            }
            .pdwindow.text see [lindex $matches 0]
            lappend find_history $findstring
            .find.win.searchin configure -text \
                [format [_ "Found '%1\$s' in %2\$s"] \
                [get_search_string] [lookup_windowname $find_in_window] ]
        } else {
            if {$::windowingsystem eq "aqua"} {bell}
            .find.win.searchin configure -text \
                [format [_ "Couldn't find '%1\$s' in %2\$s"] \
                [get_search_string] [lookup_windowname $find_in_window] ]
        }
        # done searching
        set $is_searching 0
    } else {
        if {$findstring eq $previous_findstring \
                && $wholeword_button == $previous_wholeword_button \
                    && !$window_changed} {
            pdsend "$find_in_window findagain"
        } else {
            pdsend [concat $find_in_window find [pdtk_encodedialog $findstring] \
                        $wholeword_button]
            set previous_findstring $findstring
            set previous_wholeword_button $wholeword_button
            lappend find_history $findstring
        }
        set window_changed 0
        # cancel previous search timeout
        after cancel $is_searching_id
        # just in case there is no response from pd,
        # reset is_searching after a timeout of 5s
        set is_searching_id [after 5000 set is_searching 0]
    }
    if {$::windowingsystem ne "aqua"} {
        # (GNOME/Windows) find panel should retain focus after a find
        # (yes, a bit of a kludge)
        after 100 "raise .find; ::dialog_find::focus_find"
    }
}

# mytoplevel isn't used here, but is kept for compatibility with other dialog cancel procs
proc ::dialog_find::cancel {mytoplevel} {
    variable find_in_window
    wm withdraw .find
    # focus on target window or next available
    if {[winfo exists $find_in_window] && [winfo viewable $find_in_window]} {
        focus $find_in_window
    } else {
        focus [lindex [wm stackorder .] end]
    }
}

# focus on the entry in the find dialog
proc ::dialog_find::focus_find {} {
    variable find_in_window
    # if the current search window doesn't exist (ie. was closed), set Pd window
    if {[winfo exists $find_in_window] eq 0} {
        set_window_to_search .pdwindow
    }
    focus .find.win.entry
    .find.win.entry selection range 0 end
}

# set which window to run the search in, does not update if search is in progress
proc ::dialog_find::set_window_to_search {mytoplevel} {
    variable find_in_window
    variable window_changed
    variable is_searching
    # don't change window if a search is in progress
    if {$is_searching == 1} {return}
    if {$find_in_window eq $mytoplevel} {
        set window_changed 0
    } else {
        set window_changed 1
    }
    set find_in_window $mytoplevel
    if {[winfo exists $find_in_window]} {
        if {$find_in_window eq ".find"} {
            set find_in_window [winfo toplevel [lindex [wm stackorder .] end-1]]
        }
        .find.win.searchin configure -text \
            [format [_ "Search in %s for:"] [lookup_windowname $find_in_window] ]
    }
    update_bindings
}

proc ::dialog_find::pdtk_showfindresult {mytoplevel success which total} {
    variable is_searching
    variable is_searching_id
    # done searching
    set $is_searching 0
    # cancel previous search timeout
    after cancel $is_searching_id
    if {$success eq 0} {
        if {$total eq 0} {
            if {$::windowingsystem eq "aqua"} {bell}
            set infostring \
                [format [_ "Couldn't find '%1\$s' in %2\$s"] \
                [get_search_string] [lookup_windowname $mytoplevel] ]
        } else {
            set infostring \
                [format [_ "Showed last '%1\$s' in %2\$s"] \
                [get_search_string] [lookup_windowname $mytoplevel] ]
        }
    } else {
        set infostring \
        [format [_ "Showing '%1\$d' out of %2\$d items in %3\$s"] \
            $which $total [get_search_string] [lookup_windowname $mytoplevel] ]
    }
    ::pdwindow::debug "$infostring\n"
    .find.win.searchin configure -text "$infostring"
}

# the find panel is opened from the menu and key bindings
proc ::dialog_find::open_find_dialog {mytoplevel} {
    if {[winfo exists .find]} {
        wm deiconify .find
        ::dialog_find::set_window_to_search $mytoplevel
    } else {
        create_dialog $mytoplevel
    }
    raise .find
    focus .find
    focus_find
}

proc ::dialog_find::create_dialog {mytoplevel} {
    toplevel .find
    wm title .find "Find"
    wm group .find .
    wm resizable .find 0 0
    wm transient .find
    .find configure -menu $::dialog_menubar
    
    ::pd_bindings::dialog_bindings .find "find"

# Widgets
    ttk::frame .find.win -padding 5 
    ttk::label .find.win.searchin  -text \
            [format [_ "Search in %s for:"] [_ "Pd window"] ]
    

    ttk::entry .find.win.entry -width 30 -font 18 
    
    bind .find.win.entry <Up> "::dialog_find::get_history 1"
    bind .find.win.entry <Down> "::dialog_find::get_history -1"

    ttk::frame .find.win.frame 
    ttk::checkbutton .find.win.frame.wholeword -variable ::dialog_find::wholeword_button \
        -text [_ "Match whole word only"]
                                               
    ttk::frame .find.win.frame.pad -width 48 

    # todo make it work for the other OS's
    if {$::windowingsystem eq "win32"} {
        button .find.cancel -text [_ "Cancel"] -default normal \
            -command "::dialog_find::cancel $mytoplevel"
        pack .find.cancel -side right -padx 6 -pady 3 -ipadx 10
    }
    ttk::button .find.win.frame.button -text [_ "Find"] -default active \
        -command "::dialog_find::ok $mytoplevel" 
    if {$::windowingsystem eq "x11"} {
        button .find.close -text [_ "Close"] -default normal \
            -command "::dialog_find::cancel $mytoplevel"
        pack .find.close -side right -padx 6 -pady 3 -ipadx 10
    }

# Layout
    grid .find.win -column 0 -row 0
    grid .find.win.searchin -column 0 -row 0 -pady 2
    grid .find.win.entry    -column 0 -row 1 -pady 2

    grid .find.win.frame -column 0 -row 2 -sticky nwes
    grid .find.win.frame.wholeword -column 0 -row 0
    grid .find.win.frame.pad       -column 1 -row 0 -pady 2
    grid .find.win.frame.button    -column 2 -row 0

    # on Mac OS X, the buttons shouldn't get Tab/keyboard focus
    if {$::windowingsystem eq "aqua"} {
        .find.win.frame.wholeword configure -takefocus 0
        .find.win.frame.button configure -takefocus 0
    }
    ::dialog_find::set_window_to_search $mytoplevel
}

# update the passthrough key bindings based on the current target search window
proc ::dialog_find::update_bindings {} {
    variable find_in_window
    # disable first
    bind .find <$::modifier-Key-s>       {bell; break}
    bind .find <$::modifier-Shift-Key-s> {bell; break}
    bind .find <$::modifier-Shift-Key-S> {bell; break}
    bind .find <$::modifier-Key-p>       {bell; break}
    # sending these commands to the Find Dialog Panel should forward them to
    # the currently focused patch or the pdwindow
    if {[winfo exists $find_in_window]} {
        # the "; break" part stops executing other binds
        bind .find <$::modifier-Shift-Key-s> \
            "menu_send $find_in_window menusaveas; break"
        bind .find <$::modifier-Shift-Key-S> \
            "menu_send $find_in_window menusaveas; break"
        if {$find_in_window ne ".pdwindow"} {
            # these don't do anything in the pdwindow
            bind .find <$::modifier-Key-s> \
                "menu_send $find_in_window menusave; break"
            bind .find <$::modifier-Key-p> \
                "menu_print $find_in_window; break"
        }
    }
}

# returns the current search string, shortens & appends "..." if too long
proc ::dialog_find::get_search_string {} {
    if {[winfo exists .find] eq 0} {return ""}
    if {[string length [.find.win.entry get]] > 20} {
        return [format "%s..." [string range [.find.win.entry get] 0 20]]
    } else {
        return [.find.win.entry get]
    }
}
