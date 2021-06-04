# TODO
# This whole scrollbox thing is kinda ugly and unstable
# figure out a way to consolidate it, or make it less janky
# it is working, but I'm worried that it will break in the future
package provide dialog_path 0.1

package require scrollboxwindow

namespace eval ::dialog_path:: {
    variable use_standard_paths_button 1
    variable verbose_button 0
    variable docspath ""
    variable installpath ""
    namespace export pdtk_path_dialog
}

############ pdtk_path_dialog -- run a path dialog #########

proc ::dialog_path::cancel {mytoplevel} {
    ::scrollboxwindow::cancel $mytoplevel
}

proc ::dialog_path::ok {mytoplevel} {
    ::scrollboxwindow::ok $mytoplevel dialog_path::commit
}

# set up the panel with the info from pd
proc ::dialog_path::pdtk_path_dialog {mytoplevel extrapath verbose} {
    global use_standard_paths_button
    global verbose_button
    global docspath
    global installpath
    set use_standard_paths_button $extrapath
    set verbose_button $verbose
    if {[namespace exists ::pd_docsdir]} {set docspath $::pd_docsdir::docspath}
    if {[namespace exists ::deken]} {set installpath $::deken::installpath}
    if {[winfo exists $mytoplevel]} {
        # this doesn't seem to be called...
        wm deiconify $mytoplevel
        raise $mytoplevel
        focus $mytoplevel
    } else {
        create_dialog $mytoplevel
    }
}

proc ::dialog_path::create_dialog {mytoplevel} {
    global docspath
    global installpath
    # scroll box is defined in scrollbox.tcl and scrollboxwindow.tcl
    ::scrollboxwindow::make $mytoplevel $::sys_searchpath \
        dialog_path::add dialog_path::edit dialog_path::commit \
        [_ "Search Paths"] \
        450 300 1
    wm withdraw $mytoplevel
    wm resizable $mytoplevel 0 0
    ::pd_bindings::dialog_bindings $mytoplevel "path"
    set readonly_color [lindex [$mytoplevel configure -background] end] ;# Change this color?

# Widgets (Some widgets are defined in scrollboxwindow and scrollbox)
# Path options
    ttk::frame $mytoplevel.w.pathOptions 
    ttk::checkbutton $mytoplevel.w.pathOptions.extra -text "Standard Paths" \
        -variable use_standard_paths_button 
    ttk::checkbutton $mytoplevel.w.pathOptions.verbose -text "Verbose" \
        -variable verbose_button 

# Docs Directory
    # add docsdir path widgets if pd_docsdir is loaded
    # The only time this doesn't exist is when starting pd
    # for the first time ever.
    if {[namespace exists ::pd_docsdir]} {
        set docspath $::pd_docsdir::docspath
        ttk::labelframe $mytoplevel.w.docspath -text " Documents Directory " \
            -padding 5
        ttk::frame $mytoplevel.w.docspath.path 
        ttk::entry $mytoplevel.w.docspath.path.entry -textvariable docspath -width 38 \
            -takefocus 0 -state readonly 
        ttk::button $mytoplevel.w.docspath.path.browse -text [_ "Browse"] \
            -command "::dialog_path::browse_docspath $mytoplevel" \
            
        ttk::frame $mytoplevel.w.docspath.buttons 
        ttk::button $mytoplevel.w.docspath.buttons.reset -text [_ "Reset"] \
            -command "::dialog_path::reset_docspath $mytoplevel" \
            
        ttk::button $mytoplevel.w.docspath.buttons.disable -text [_ "Disable"] \
            -command "::dialog_path::disable_docspath $mytoplevel" \
            
        # scroll to right for long paths
        $mytoplevel.w.docspath.path.entry xview moveto 1
    }

# Deken
    # deken comes with pd defacto now
    if {[namespace exists ::deken]} {
        ttk::labelframe $mytoplevel.w.installpath -text " Externals Install Directory " \
            -padding 5
        ttk::frame $mytoplevel.w.installpath.path 
        ttk::entry $mytoplevel.w.installpath.path.entry -textvariable installpath -width 38 \
            -takefocus 0 -state readonly
        ttk::button $mytoplevel.w.installpath.path.browse -text [_ "Browse"] \
            -command "::dialog_path::browse_installpath $mytoplevel" \
            

        ttk::frame $mytoplevel.w.installpath.buttons 
        ttk::button $mytoplevel.w.installpath.buttons.reset -text [_ "Reset"] \
            -command "::dialog_path::reset_installpath $mytoplevel" \
            
        ttk::button $mytoplevel.w.installpath.buttons.clear -text [_ "Clear"] \
            -command "::dialog_path::clear_installpath $mytoplevel" \
            
        # scroll to right for long paths
        $mytoplevel.w.installpath.path.entry xview moveto 1
    }

# Layout
    # listbox widgets (defined in scrollbox.tcl)
    grid $mytoplevel.w -column 0 -row 0 -stick nwes
    grid $mytoplevel.w.listbox -column 0 -row 0 -sticky nwes
    grid $mytoplevel.w.listbox.box -column 0 -row 0 -sticky nwes
    grid $mytoplevel.w.listbox.scrollbar -column 1 -row 0 -sticky ns

    grid $mytoplevel.w.actions -column 0 -row 1 -sticky w -pady 4
    grid $mytoplevel.w.actions.add_path -column 0 -row 0
    grid $mytoplevel.w.actions.edit_path -column 1 -row 0
    grid $mytoplevel.w.actions.delete_path -column 2 -row 0

    # Path Options
    grid $mytoplevel.w.pathOptions -column 0 -row 2 -sticky w -pady 4
    grid $mytoplevel.w.pathOptions.extra -column 0 -row 0
    grid $mytoplevel.w.pathOptions.verbose -column 1 -row 0

    # Docs Directory
    if {[namespace exists ::pd_docsdir]} {
        grid $mytoplevel.w.docspath -column 0 -row 3 -sticky nwes -pady 4
        grid $mytoplevel.w.docspath.path -column 0 -row 0
        grid $mytoplevel.w.docspath.path.entry -column 0 -row 0
        grid $mytoplevel.w.docspath.path.browse -column 1 -row 0

        grid $mytoplevel.w.docspath.buttons -column 0 -row 1 -sticky w
        grid $mytoplevel.w.docspath.buttons.reset -column 0 -row 0
        grid $mytoplevel.w.docspath.buttons.disable -column 1 -row 0
    }

    # Deken 
    if {[namespace exists ::deken]} {
        grid $mytoplevel.w.installpath -column 0 -row 4 -sticky nwes -pady 4
        grid $mytoplevel.w.installpath.path -column 0 -row 0
        grid $mytoplevel.w.installpath.path.entry -column 0 -row 0
        grid $mytoplevel.w.installpath.path.browse -column 1 -row 0

        grid $mytoplevel.w.installpath.buttons -column 0 -row 1 -sticky w
        grid $mytoplevel.w.installpath.buttons.reset -column 0 -row 0
        grid $mytoplevel.w.installpath.buttons.clear -column 1 -row 0
    }

    # Buttons (these are defined in scrollboxwindow.tcl)
    grid $mytoplevel.w.buttonframe -column 0 -row 5
    grid $mytoplevel.w.buttonframe.ok -column 0 -row 0
    grid $mytoplevel.w.buttonframe.apply -column 1 -row 0
    grid $mytoplevel.w.buttonframe.cancel -column 2 -row 0

# focus handling on OSX
    if {$::windowingsystem eq "aqua"} {

        # unbind ok button when in listbox
        bind $mytoplevel.w.listbox.box <FocusIn> "::dialog_path::unbind_return $mytoplevel"
        bind $mytoplevel.w.listbox.box <FocusOut> "::dialog_path::rebind_return $mytoplevel"

        # remove cancel button from focus list since it's not activated on Return
        $mytoplevel.w.buttonframe.cancel config -takefocus 0

        # show active focus on the ok button as it *is* activated on Return
        $mytoplevel.w.buttonframe.ok config -default normal
        bind $mytoplevel.w.buttonframe.ok <FocusIn> "$mytoplevel.w.buttonframe.ok config -default active"
        bind $mytoplevel.w.buttonframe.ok <FocusOut> "$mytoplevel.w.buttonframe.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        # $mytoplevel.w.buttonframe.ok config -highlightthickness 0
        # $mytoplevel.w.buttonframe.cancel config -highlightthickness 0
    }

    # re-adjust height based on optional sections
    update
    wm minsize $mytoplevel [winfo width $mytoplevel] [winfo reqheight $mytoplevel]

    position_over_window $mytoplevel .pdwindow
    raise $mytoplevel
}

# browse for a new Pd user docs path
proc ::dialog_path::browse_docspath {mytoplevel} {
    global docspath
    global installpath
    # set the new docs dir
    set newpath [tk_chooseDirectory -initialdir $::env(HOME) \
                                    -title [_ "Choose Pd documents directory:"]]
    if {$newpath ne ""} {
        set docspath $newpath
        set installpath [::pd_docsdir::get_externals_path "$docspath"]
        $mytoplevel.w.docspath.path.entry xview moveto 1
        return 1
    }
    return 0
}

# ignore the Pd user docs path
proc ::dialog_path::disable_docspath {mytoplevel} {
    global docspath
    set docspath [::pd_docsdir::get_disabled_path]
    return 1
}

# reset to the default Pd user docs path
proc ::dialog_path::reset_docspath {mytoplevel} {
    global docspath
    global installpath
    set docspath [::pd_docsdir::get_default_path]
    set installpath [::pd_docsdir::get_externals_path "$docspath"]
    $mytoplevel.w.docspath.path.entry xview moveto 1
    return 1
}

# browse for a new deken installpath, this assumes deken is available
proc ::dialog_path::browse_installpath {mytoplevel} {
    global installpath
    if {![file isdirectory $installpath]} {
        set initialdir $::env(HOME)
    } else {
        set initialdir $installpath
    }
    set newpath [tk_chooseDirectory -initialdir $initialdir \
                                    -title [_ "Install externals to directory:"]]
    if {$newpath ne ""} {
        set installpath $newpath
        $mytoplevel.w.installpath.path.entry xview moveto 1
        return 1
    }
    return 0
}

# reset to default deken installpath
proc ::dialog_path::reset_installpath {mytoplevel} {
    global installpath
    set installpath [::deken::find_installpath true]
    $mytoplevel.w.installpath.path.entry xview moveto 1
}

# clear the deken installpath
proc ::dialog_path::clear_installpath {mytoplevel} {
    global installpath
    set installpath ""
}

# for focus handling on OSX
proc ::dialog_path::rebind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Escape> "::dialog_path::cancel $mytoplevel"
    bind $mytoplevel <KeyPress-Return> "::dialog_path::ok $mytoplevel"
    focus $mytoplevel.w.buttonframe.ok
    return 0
}

# for focus handling on OSX
proc ::dialog_path::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Escape> break
    bind $mytoplevel <KeyPress-Return> break
    return 1
}

############ pdtk_path_dialog -- dialog window for search path #########
proc ::dialog_path::choosePath {currentpath title} {
    if {$currentpath == ""} {
        set currentpath $::env(HOME)
    }
    return [tk_chooseDirectory -initialdir $currentpath -title $title]
}

proc ::dialog_path::add {} {
    return [::dialog_path::choosePath "" [_ "Add a new path"]]
}

proc ::dialog_path::edit {currentpath} {
    return [::dialog_path::choosePath $currentpath "Edit existing path \[$currentpath\]"]
}

proc ::dialog_path::commit {new_path} {
    global use_standard_paths_button
    global verbose_button
    global docspath
    global installpath

    # save buttons and search paths
    set changed false
    if {"$new_path" ne "$::sys_searchpath"} {set changed true}
    set ::sys_searchpath $new_path
    pdsend "pd path-dialog $use_standard_paths_button $verbose_button [pdtk_encode $::sys_searchpath]"
    if {$changed} {::helpbrowser::refresh}

    # save installpath
    if {[namespace exists ::deken]} {
        # clear first so set_installpath doesn't pick up prev value from guiprefs
        set ::deken::installpath ""
        ::deken::set_installpath $installpath
    }

    # save docspath
    if {[namespace exists ::pd_docsdir]} {
        # run this after since it checks ::deken::installpath value
        ::pd_docsdir::update_path $docspath
    }
}
