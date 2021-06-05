
package provide pdwindow 0.1

namespace eval ::pdwindow:: {
    variable logbuffer {}
    variable tclentry {}
    variable tclentry_history {"console show"}
    variable history_position 0
    variable linecolor 0 ;# is toggled to alternate text line colors
    variable logmenuitems
    variable maxloglevel 4

    variable lastlevel 0

    namespace export create_window
    namespace export pdtk_post
    namespace export pdtk_pd_dsp
    namespace export pdtk_pd_dio
    namespace export pdtk_pd_audio
}

# TODO make the Pd window save its size and location between running

proc ::pdwindow::set_layout {} {
    variable maxloglevel
    $::win.text.internal tag configure log0 -foreground \
    	[::pdtk_canvas::get_color pdwindow_fatal_text .pdwindow] -background \
    	[::pdtk_canvas::get_color pdwindow_fatal_highlight .pdwindow]
    $::win.text.internal tag configure log1 -foreground \
    	[::pdtk_canvas::get_color pdwindow_error_text .pdwindow]
    $::win.text.internal tag configure log2 -foreground \
    	[::pdtk_canvas::get_color pdwindow_post_text .pdwindow]
    $::win.text.internal tag configure log3 -foreground \
    	[::pdtk_canvas::get_color pdwindow_debug_text .pdwindow]

    # 0-20(4-24) is a rough useful range of 'verbose' levels for impl debugging
    set start 4
    set end 25
    for {set i $start} {$i < $end} {incr i} {
        set B [expr int(($i - $start) * (40 / ($end - $start))) + 50]
        $::win.text.internal tag configure log${i} -foreground grey${B}
    }
}


# grab focus on part of the Pd window when Pd is busy
proc ::pdwindow::busygrab {} {
    # set the mouse cursor to look busy and grab focus so it stays that way
    $::win.text configure -cursor watch
    grab set $::win.text
}

# release focus on part of the Pd window when Pd is finished
proc ::pdwindow::busyrelease {} {
    $::win.text configure -cursor xterm
    grab release $::win.text
}

# ------------------------------------------------------------------------------
# pdtk functions for 'pd' to send data to the Pd window

proc ::pdwindow::buffer_message {object_id level message} {
    variable logbuffer
    lappend logbuffer $object_id $level $message
}

proc ::pdwindow::insert_log_line {object_id level message} {
    set message [subst -nocommands -novariables $message]
    if {$object_id eq ""} {
        $::win.text.internal insert end $message log$level
    } else {
        $::win.text.internal insert end $message [list log$level obj$object_id]
        $::win.text.internal tag bind obj$object_id <$::modifier-ButtonRelease-1> \
            "::pdwindow::select_by_id $object_id; break"
        $::win.text.internal tag bind obj$object_id <Key-Return> \
            "::pdwindow::select_by_id $object_id; break"
        $::win.text.internal tag bind obj$object_id <Key-KP_Enter> \
            "::pdwindow::select_by_id $object_id; break"
    }
}

# this has 'args' to satisfy trace, but its not used
proc ::pdwindow::filter_buffer_to_text {args} {
    variable logbuffer
    variable maxloglevel
    $::win.text.internal delete 0.0 end
    set i 0
    foreach {object_id level message} $logbuffer {
        if { $level <= $::loglevel || $maxloglevel == $::loglevel} {
            insert_log_line $object_id $level $message
        }
        # this could take a while, so update the GUI every 10000 lines
        if { [expr $i % 10000] == 0} {update idletasks}
        incr i
    }
    $::win.text.internal yview end
    ::pdwindow::verbose 10 "the Pd window filtered $i lines\n"
}

proc ::pdwindow::select_by_id {args} {
    if [llength $args] { # Is $args empty?
        pdsend "pd findinstance $args"
    }
}

# logpost posts to Pd window with an object to trace back to and a
# 'log level'. The logpost and related procs are for generating
# messages that are useful for debugging patches.  They are messages
# that are meant for the Pd programmer to see so that they can get
# information about the patches they are building
proc ::pdwindow::logpost {object_id level message} {
    variable maxloglevel
    variable lastlevel $level

    buffer_message $object_id $level $message
    if {[llength [info commands .pdwindow.w.text.internal]] &&
        ($level <= $::loglevel || $maxloglevel == $::loglevel)} {
        # cancel any pending move of the scrollbar, and schedule it
        # after writing a line. This way the scrollbar is only moved once
        # when the inserting has finished, greatly speeding things up
        after cancel $::win.text.internal yview end
        insert_log_line $object_id $level $message
        after idle $::win.text.internal yview end
    }
    # -stderr only sets $::stderr if 'pd-gui' is started before 'pd'
    if {$::stderr} {puts stderr $message}
}

# shortcuts for posting to the Pd window
proc ::pdwindow::fatal {message} {logpost {} 0 $message}
proc ::pdwindow::error {message} {logpost {} 1 $message}
proc ::pdwindow::post  {message} {logpost {} 2 $message}
proc ::pdwindow::debug {message} {logpost {} 3 $message}
# for backwards compatibility
proc ::pdwindow::bug {message} {logpost {} 1 \
    [concat consistency check failed: $message]}
proc ::pdwindow::pdtk_post {message} {post $message}

proc ::pdwindow::endpost {} {
    variable linecolor
    variable lastlevel
    logpost {} $lastlevel "\n"
    set linecolor [expr ! $linecolor]
}

# this verbose proc has a separate numbering scheme since its for
# debugging implementations, and therefore falls outside of the 0-3
# numbering on the Pd window.  They should only be shown in ALL mode.
proc ::pdwindow::verbose {level message} {
    incr level 4
    logpost {} $level $message
}

# clear the log and the buffer
proc ::pdwindow::clear_console {} {
    variable logbuffer {}
    $::win.text.internal delete 0.0 end
}

# save the contents of the pdwindow::logbuffer to a file
proc ::pdwindow::save_logbuffer_to_file {} {
    variable logbuffer
    set filename [tk_getSaveFile -initialfile "pdwindow.txt" -defaultextension .txt]
    if {$filename eq ""} return; # they clicked cancel
    set f [open $filename w]
    puts $f "Pd $::PD_MAJOR_VERSION.$::PD_MINOR_VERSION-$::PD_BUGFIX_VERSION$::PD_TEST_VERSION on $::tcl_platform(os) $::tcl_platform(machine)"
    puts $f "--------------------------------------------------------------------------------"
    foreach {object_id level message} $logbuffer {
        puts -nonewline $f $message
    }
    ::pdwindow::post "saved console to: $filename\n"
    close $f
}
# this has 'args' to satisfy trace, but its not used
proc ::pdwindow::loglevel_updated {level UNUSED} {
    switch $level {
        0 { set ::loglevel 0 }
        1 { set ::loglevel 1 }
        2 { set ::loglevel 2 }
        3 { set ::loglevel 3 }
        4 { set ::loglevel 4 }
    } 
    ::pdwindow::filter_buffer_to_text $level
    ::pd_guiprefs::write_loglevel
}

#--compute audio/DSP checkbutton-----------------------------------------------#

# set the checkbox on the "DSP" menuitems and checkbox
proc ::pdwindow::pdtk_pd_dsp {value} {
    # TODO canvas_startdsp/stopdsp should really send 1 or 0, not "ON" or "OFF"
    if {$value eq "ON"} {
        set ::dsp 1
    } else {
        set ::dsp 0
    }
}

proc ::pdwindow::pdtk_pd_dio {error} {
    ttk::style configure good.TLabel -background "#1c1c1c" -foreground "#1c1c1c"
    ttk::style congifure bad.TLabel -background "#1c1c1c" -foreground "#ea6962"
    if {$error == 1} {
        $::win.header.dio -style bad.TLabel
    } else {
        $::win.header.dio -style good.TLabel
    }
}

proc ::pdwindow::pdtk_pd_audio {state} {
    # set strings so these can be translated
    # state values are "on" or "off"
    if {$state eq "on"} {
        set labeltext [_ "Audio on"]
    } elseif {$state eq "off"} {
        set labeltext [_ "Audio off"]
    } else {
        # fallback in case the $state values change in the future
        set labeltext [concat Audio $state]
    }
    # $::win.header.ioframe.iostate configure -text $labeltext
}

#--bindings specific to the Pd window------------------------------------------#

proc ::pdwindow::pdwindow_bindings {} {
    # these bindings are for the whole Pd window, minus the Tcl entry
    foreach window {$::win.text $::win.header} {
        bind $window <$::modifier-Key-x> "tk_textCut $::win.text"
        bind $window <$::modifier-Key-c> "tk_textCopy $::win.text"
        bind $window <$::modifier-Key-v> "tk_textPaste $::win.text"
    }
    # Select All doesn't seem to work unless its applied to the whole window
    bind .pdwindow <$::modifier-Key-a> "$::win.text tag add sel 1.0 end"
    # the "; break" part stops executing another binds, like from the Text class

    # these don't do anything in the Pd window, so alert the user, then break
    # so no more bindings run
    bind .pdwindow <$::modifier-Key-s> {bell; break}
    bind .pdwindow <$::modifier-Key-p> {bell; break}

    # ways of hiding/closing the Pd window
    if {$::windowingsystem eq "aqua"} {
        # on Mac OS X, you can close the Pd window, since the menubar is there
        bind .pdwindow <$::modifier-Key-w>   "wm withdraw .pdwindow"
        wm protocol .pdwindow WM_DELETE_WINDOW "wm withdraw .pdwindow"
    } else {
        # TODO should it possible to close the Pd window and keep Pd open?
        bind .pdwindow <$::modifier-Key-w>   "wm iconify .pdwindow"
        wm protocol .pdwindow WM_DELETE_WINDOW "pdsend \"pd verifyquit\""
    }
}

#--Tcl entry procs-------------------------------------------------------------#

proc ::pdwindow::eval_tclentry {} {
    variable tclentry
    variable tclentry_history
    variable history_position 0
    if {$tclentry eq ""} {return} ;# no need to do anything if empty
    if {[catch {uplevel #0 $tclentry} errorname]} {
        global errorInfo
        switch -regexp -- $errorname { "missing close-brace" {
                ::pdwindow::error [concat [_ "(Tcl) MISSING CLOSE-BRACE '\}': "] $errorInfo]\n
            } "missing close-bracket" {
                ::pdwindow::error [concat [_ "(Tcl) MISSING CLOSE-BRACKET '\]': "] $errorInfo]\n
            } "^invalid command name" {
                ::pdwindow::error [concat [_ "(Tcl) INVALID COMMAND NAME: "] $errorInfo]\n
            } default {
                ::pdwindow::error [concat [_ "(Tcl) UNHANDLED ERROR: "] $errorInfo]\n
            }
        }
    }
    lappend tclentry_history $tclentry
    set tclentry {}
}

proc ::pdwindow::get_history {direction} {
    variable tclentry_history
    variable history_position

    incr history_position $direction
    if {$history_position < 0} {set history_position 0}
    if {$history_position > [llength $tclentry_history]} {
        set history_position [llength $tclentry_history]
    }
    $::win.tcl.entry delete 0 end
    $::win.tcl.entry insert 0 \
        [lindex $tclentry_history end-[expr $history_position - 1]]
}

proc ::pdwindow::validate_tcl {} {
    variable tclentry
    if {[info complete $tclentry]} {
        $::win.tcl.entry configure -background "white"
    } else {
        $::win.tcl.entry configure -background "#FFF0F0"
    }
}

#--create tcl entry-----------------------------------------------------------#

proc ::pdwindow::create_tcl_entry {} {
# Tcl entry box frame
    label $::win.tcl.label -text [_ "Tcl:"] -anchor e
    pack $::win.tcl.label -side left
    entry $::win.tcl.entry -width 200 \
       -exportselection 1 -insertwidth 2 -insertbackground blue \
       -textvariable ::pdwindow::tclentry -font TkTextFont
    pack $::win.tcl.entry -side left -fill x
# bindings for the Tcl entry widget
    bind $::win.tcl.entry <$::modifier-Key-a> "%W selection range 0 end; break"
    bind $::win.tcl.entry <Return> "::pdwindow::eval_tclentry"
    bind $::win.tcl.entry <Up>     "::pdwindow::get_history 1"
    bind $::win.tcl.entry <Down>   "::pdwindow::get_history -1"
    bind $::win.tcl.entry <KeyRelease> +"::pdwindow::validate_tcl"

    bind $::win.text <Key-Tab> "focus $::win.tcl.entry; break"
}

proc ::pdwindow::set_findinstance_cursor {widget key state} {
    set triggerkeys [list Control_L Control_R Meta_L Meta_R]
    if {[lsearch -exact $triggerkeys $key] > -1} {
        if {$state == 0} {
            $widget configure -cursor xterm
        } else {
            $widget configure -cursor based_arrow_up
        }
    }
}

#--create the window-----------------------------------------------------------#

proc ::pdwindow::create_window {} {
    variable logmenuitems
    set ::loaded(.pdwindow) 0

    toplevel .pdwindow -class PdWindow
    wm title .pdwindow "Pure Data"
    set ::windowname(.pdwindow) "Pd"
    if {$::windowingsystem eq "x11"} {
        wm minsize .pdwindow 400 75
    } else {
        wm minsize .pdwindow 250 51 ;# 51 b/c of header size
        wm maxsize .pdwindow 600 451 ;# 4:3 ratio
    }
    # I'm just using the size that the grid manager
    # wants, but if I wanted to change that in the future
    # and start with a different size, use this line
    # wm geometry .pdwindow <dimensions and offset here>
    

# Widgets
    ttk::frame .pdwindow.w
    set ::win .pdwindow.w 
    ttk::frame $::win.header -padding 5 -style header.TFrame
    # TODO make this a button, for now this is a checkbox
    ttk::checkbutton $::win.header.dsp -text [_ "DSP"] -variable ::dsp \
        -takefocus 1 -command {pdsend "pd dsp $::dsp"}

# DIO error label
    ttk::label $::win.header.dio \
        -text "Audio I/O error" \
        -takefocus 0 \
        -font {$::font_family -11}

    ttk::frame $::win.header.pad -width 210 -height 43
    ttk::label $::win.header.loglabel -text [_ "Log:"]

    set loglevels {0 1 2 3 4}
    set logmenuitems [list  "0 fatal" "1 error" "2 normal" "3 debug" "4 all"]
    ttk::menubutton $::win.header.logmenu -menu $::win.header.logmenu.items \
        -textvariable ::loglevel -width 2

    menu $::win.header.logmenu.items
    foreach i $logmenuitems { 
        $::win.header.logmenu.items add command -label $i
    }
    foreach i $logmenuitems { 
        $::win.header.logmenu.items entryconfigure $i -command "::pdwindow::loglevel_updated $i" 
    }

    # TODO figure out how to make the menu traversable with the keyboard
    #$::win.header.logmenu configure -takefocus 1
    ttk::frame $::win.tcl -borderwidth 0

    ttk::frame $::win.console 

    # TODO this should use the pd_font_$size created in pd-gui.tcl
    tk::text $::win.text -bd 0 -font {$::font_family 10} \
        -highlightthickness 0 -borderwidth 0 -relief flat \
        -yscrollcommand "$::win.scroll set" -width 60 \
        -undo false -autoseparators false -maxundo 1 -takefocus 0
    ttk::scrollbar $::win.scroll -command "$::win.text.internal yview"

# Layout
    grid $::win -column 0 -row 0 -sticky nwes
    grid $::win.header -column 0 -row 0 -sticky nwes -columnspan 2
    grid $::win.header.dsp      -column 0 -row 0
    grid $::win.header.dio      -column 1 -row 0 -padx 10
    grid $::win.header.pad      -column 2 -row 0
    grid $::win.header.loglabel -column 3 -row 0
    grid $::win.header.logmenu  -column 4 -row 0

    grid $::win.text   -column 0 -row 1 -sticky nwes
    grid $::win.scroll -column 1 -row 1 -sticky ns -padx 1 -pady 1

# Resize
    grid columnconfigure .pdwindow 0 -weight 1
    grid rowconfigure .pdwindow 0 -weight 1
    grid columnconfigure $::win 0 -weight 1
    grid rowconfigure $::win 0 -weight 0
    grid rowconfigure $::win 1 -weight 1

    grid columnconfigure $::win.header 0 -weight 0
    grid columnconfigure $::win.header 1 -weight 0
    grid columnconfigure $::win.header 2 -weight 1
    grid columnconfigure $::win.header 3 -weight 0
    grid columnconfigure $::win.header 4 -weight 0

    raise .pdwindow
    focus $::win.text
    # run bindings last so that $::win.tcl.entry exists
    pdwindow_bindings
    # set cursor to show when clicking in 'findinstance' mode
    bind .pdwindow <KeyPress> "+::pdwindow::set_findinstance_cursor %W %K %s"
    bind .pdwindow <KeyRelease> "+::pdwindow::set_findinstance_cursor %W %K %s"

    # hack to make a good read-only text widget from http://wiki.tcl.tk/1152
    rename ::$::win.text ::$::win.text.internal
    proc ::.pdwindow.w.text {args} {
        switch -exact -- [lindex $args 0] {
            "insert" {}
            "delete" {}
            "default" { return [eval ::$::win.text.internal $args] }
        }
    }

    # print whatever is in the queue after the event loop finishes
    after idle [list after 0 ::pdwindow::filter_buffer_to_text]

    set ::loaded(.pdwindow) 1
}

#--configure the window menu---------------------------------------------------#

proc ::pdwindow::create_window_finalize {} {
    # wait until .pdwindow.tcl.entry is visible before opening files so that
    # the loading logic can grab it and put up the busy cursor

    # this ought to be called after all elements of the window (including the
    # menubar!) have been created!
    if {![winfo viewable $::win.text]} { tkwait visibility $::win.text }
    set fontsize [::pd_guiprefs::read menu-fontsize]
    if {$fontsize != ""} {
        ::dialog_font::apply .pdwindow $fontsize
    }
}

proc ::pdwindow::configure_window_offset {{winid .pdwindow}} {
    # on X11 measure the size of the window decoration, so we can open windows at the correct position
    if {$::windowingsystem eq "x11"} {
        if {[winfo viewable $winid]} {
            # wait for possible race-conditions at startup...
            # I've removed pad1, not sure what it ever did anyways
            if {[winfo viewable .pdwindow] } {
            }

            regexp -- {([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)} [wm geometry $winid] -> \
                _ _ _left _top
            set ::windowframex [expr {[winfo rootx $winid] - $_left}]
            set ::windowframey [expr {[winfo rooty $winid] - $_top}]

            #puts "======================="
            #puts "[wm geometry $winid]"
            #puts "winfo [winfo rootx $winid] [winfo rooty $winid]"
            #puts "windowframe: $winid $::windowframex $::windowframey"
            #puts "======================="
        }
    }
}


# this needs to happen *after* the main menu is created, otherwise the default Wish
# menu is not replaced by the custom Apple menu on OSX
proc ::pdwindow::configure_menubar {} {
    .pdwindow configure -menu .menubar
}

# we can only get theme and colors from plugin after it loads
proc ::pdwindow::set_colors {} {
	# set some layout variables
    ::pdwindow::set_layout

    # these are here because they are different from the default theme
    ttk::style configure s.TCheckbutton -background "#1c1c1c" -foreground "#ddc7a1"
    ttk::style map s.TCheckbutton -background [list active "#292828"]
    ttk::style configure s.TFrame -background "#1c1c1c"
    ttk::style configure s.TLabel -background "#1c1c1c" -foreground "#ddc7a1"
    ttk::style configure dio.TLabel -background "#1c1c1c" -foreground "#1c1c1c"
    ttk::style configure s.TMenubutton -foreground "#ddc7a1"
    ttk::style map s.TMenubutton -foreground [list hover "#292828"] 

    $::win.header configure -style s.TFrame
    $::win.header.pad configure -style s.TFrame

    $::win.header.loglabel configure -style s.TLabel
    $::win.header.dio configure -style dio.TLabel

    $::win.header.logmenu configure -style s.TMenubutton

    $::win.header.dsp configure -style s.TCheckbutton

    $::win.text configure -background [::pdtk_canvas::get_color pdwindow_fill .pdwindow]
    # make the insert blend in with the background
    $::win.text configure -insertbackground [::pdtk_canvas::get_color pdwindow_fill .pdwindow]
}
