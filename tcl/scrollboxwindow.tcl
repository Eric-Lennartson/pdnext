
####### scrollboxwindow -- scrollbox window with default bindings #########
## This is the base dialog behind the Path and Startup dialogs
## This namespace specifies everything the two dialogs have in common,
## with arguments specifying the differences
##
## By default, this creates a dialog centered on the viewing area of the screen
## with cancel, apply, and OK buttons
## which contains a scrollbox widget populated with the given data

# TODO
# bug when clicking on scrollbar, fix it?

package provide scrollboxwindow 0.1

package require scrollbox

namespace eval scrollboxwindow {
}

proc ::scrollboxwindow::get_listdata {mytoplevel} {
    return [$mytoplevel.w.listbox.box get 0 end]
}

proc ::scrollboxwindow::do_apply {mytoplevel commit_method listdata} {
    $commit_method $listdata
    pdsend "pd save-preferences"
}

# Cancel button action
proc ::scrollboxwindow::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

# Apply button action
proc ::scrollboxwindow::apply {mytoplevel commit_method } {
    do_apply $mytoplevel $commit_method [get_listdata $mytoplevel]
}

# OK button action
# The "commit" action can take a second or more,
# long enough to be noticeable, so we only write
# the changes after closing the dialog
proc ::scrollboxwindow::ok {mytoplevel commit_method } {
    set listdata [get_listdata $mytoplevel]
    cancel $mytoplevel
    do_apply $mytoplevel $commit_method $listdata
}

# "Constructor" function for building the window
# mytoplevel -- the window id to use
# listdata -- the data used to populate the scrollbox
# add_method -- a reference to a proc to be called when the user adds a new item
# edit_method -- same as above, for editing and existing item
# commit_method -- same as above, to commit during the "apply" action
# title -- top-level title for the dialog
# width, height -- initial width and height dimensions for the window, also minimum size
# resizable -- 0 or 1, set to 1 for dialog to be resizeable
proc ::scrollboxwindow::make {mytoplevel listdata add_method edit_method commit_method title width height resizable } {
    wm deiconify .pdwindow
    raise .pdwindow
    toplevel $mytoplevel -class DialogWindow
    wm title $mytoplevel $title
    wm group $mytoplevel .
    if {$resizable == 0} {
        wm resizable $mytoplevel 0 0
    }
    wm transient $mytoplevel .pdwindow
    wm protocol $mytoplevel WM_DELETE_WINDOW "::scrollboxwindow::cancel $mytoplevel"

    # # Enforce a minimum size for the window
    # wm minsize $mytoplevel $width $height

    # # Set the current dimensions of the window
    # wm geometry $mytoplevel "${width}x${height}"

    # Add the scrollbox widget
    ::scrollbox::make $mytoplevel $listdata $add_method $edit_method

    # buttons
    # $mytoplevel.w is defined in scrollbox.tcl
    ttk::frame $mytoplevel.w.buttonframe

    ttk::button $mytoplevel.w.buttonframe.cancel -text "Cancel" \
        -command "::scrollboxwindow::cancel $mytoplevel" \

    ttk::button $mytoplevel.w.buttonframe.apply -text "Apply" \
        -command "::scrollboxwindow::apply $mytoplevel $commit_method" \

    ttk::button $mytoplevel.w.buttonframe.ok -text "OK" \
        -command "::scrollboxwindow::ok $mytoplevel $commit_method" \


}
