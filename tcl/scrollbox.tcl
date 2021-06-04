######### scrollbox -- utility scrollbar with default bindings #######
# scrollbox is used in the Path and Startup dialogs to edit lists of options

package provide scrollbox 0.1

namespace eval scrollbox {
    # This variable keeps track of the last list element we clicked on,
    # used to implement drag-drop reordering of list items
    variable lastIdx 0
}

proc ::scrollbox::get_curidx { mytoplevel } {
    set idx [$mytoplevel.w.listbox.box index active]
    if {$idx < 0 || \
            $idx == [$mytoplevel.w.listbox.box index end]} {
        return [expr {[$mytoplevel.w.listbox.box index end] + 1}]
    }
    return [expr $idx]
}

proc ::scrollbox::insert_item { mytoplevel idx name } {
    if {$name != ""} {
        $mytoplevel.w.listbox.box insert $idx $name
        set activeIdx [expr {[$mytoplevel.w.listbox.box index active] + 1}]
        $mytoplevel.w.listbox.box see $activeIdx
        $mytoplevel.w.listbox.box activate $activeIdx
        $mytoplevel.w.listbox.box selection clear 0 end
        $mytoplevel.w.listbox.box selection set active
        focus $mytoplevel.w.listbox.box
    }
}

proc ::scrollbox::add_item { mytoplevel add_method } {
    set dir [$add_method]
    insert_item $mytoplevel [expr {[get_curidx $mytoplevel] + 1}] $dir
}

proc ::scrollbox::edit_item { mytoplevel edit_method } {
    set idx [expr {[get_curidx $mytoplevel]}]
    set initialValue [$mytoplevel.w.listbox.box get $idx]
    if {$initialValue != ""} {
        set dir [$edit_method $initialValue]

        if {$dir != ""} {
            $mytoplevel.w.listbox.box delete $idx
            insert_item $mytoplevel $idx $dir
        }
        $mytoplevel.w.listbox.box activate $idx
        $mytoplevel.w.listbox.box selection clear 0 end
        $mytoplevel.w.listbox.box selection set active
        focus $mytoplevel.w.listbox.box
    }
}

proc ::scrollbox::delete_item { mytoplevel } {
    set cursel [$mytoplevel.w.listbox.box curselection]
    foreach idx $cursel {
        $mytoplevel.w.listbox.box delete $idx
    }
    $mytoplevel.w.listbox.box selection set active
}

# Double-clicking on the listbox should edit the current item,
# or add a new one if there is no current
proc ::scrollbox::dbl_click { mytoplevel edit_method add_method x y } {
    if { $x == "" || $y == "" } {
        return
    }

    set curBB [$mytoplevel.w.listbox.box bbox @$x,$y]

    # listbox bbox returns an array of 4 items in the order:
    # left, top, width, height
    set height [lindex $curBB 3]
    set top [lindex $curBB 1]
    if { $height == "" || $top == "" } {
        # If for some reason we didn't get valid bbox info,
        # we want to default to adding a new item
        set height 0
        set top 0
        set y 1
    }

    set bottom [expr {$height + $top}]

    if {$y > $bottom} {
        add_item $mytoplevel $add_method
    } else {
        edit_item $mytoplevel $edit_method
    }
}

proc ::scrollbox::click { mytoplevel x y } {
    # record the index of the current element being
    # clicked on
    variable lastIdx [$mytoplevel.w.listbox.box index @$x,$y]

    focus $mytoplevel.w.listbox.box
}

# For drag-and-drop reordering, recall the last-clicked index
# and move it to the position of the item currently under the mouse
proc ::scrollbox::release { mytoplevel x y } {
    variable lastIdx
    set curIdx [$mytoplevel.w.listbox.box index @$x,$y]

    if { $curIdx != $lastIdx } {
        # clear any current selection
        $mytoplevel.w.listbox.box selection clear 0 end

        set oldIdx $lastIdx
        set newIdx [expr {$curIdx+1}]
        set selIdx $curIdx

        if { $curIdx < $lastIdx } {
            set oldIdx [expr {$lastIdx + 1}]
            set newIdx $curIdx
            set selIdx $newIdx
        }

        $mytoplevel.w.listbox.box insert $newIdx [$mytoplevel.w.listbox.box get $lastIdx]
        $mytoplevel.w.listbox.box delete $oldIdx
        $mytoplevel.w.listbox.box activate $newIdx
        $mytoplevel.w.listbox.box selection set $selIdx
    }
}

# Make a scrollbox widget in a given window and set of data.
#
# id - the parent window for the scrollbox
# listdata - array of data to populate the scrollbox
# add_method - method to be called when we add a new item
# edit_method - method to be called when we edit an existing item
proc ::scrollbox::make { mytoplevel listdata add_method edit_method } {
    # This frame will encompass all the widgets in path and startup dialogs as well
    ttk::frame $mytoplevel.w -padding 5 

    ttk::frame $mytoplevel.w.listbox
    # WARN, this width value is very fragile, improvements?
    # todo, set these colors somewhere else, a tcl plugin maybe?
    tk::listbox $mytoplevel.w.listbox.box -relief flat -highlightthickness 0 \
        -selectmode browse -activestyle dotbox -width 48 \
        -yscrollcommand [list "$mytoplevel.w.listbox.scrollbar" set] \
        -background "#45403d" -foreground "#ddc7a1" \
        -selectbackground "#665c54" -selectforeground "#7daea3"

    # Create a scrollbar and keep it in sync with the current
    # listbox view
    ttk::scrollbar "$mytoplevel.w.listbox.scrollbar" -command [list $mytoplevel.w.listbox.box yview]] 

    # Populate the listbox widget
    # Here's where we can change the line color
    foreach item $listdata {
        $mytoplevel.w.listbox.box insert end $item
    }

    # Standard listbox key/mouse bindings
    event add <<Delete>> <Delete>
    if { $::windowingsystem eq "aqua" } { event add <<Delete>> <BackSpace> }

    bind $mytoplevel.w.listbox.box <ButtonPress> "::scrollbox::click $mytoplevel %x %y"
    bind $mytoplevel.w.listbox.box <Double-1> "::scrollbox::dbl_click $mytoplevel $edit_method $add_method %x %y"
    bind $mytoplevel.w.listbox.box <ButtonRelease> "::scrollbox::release $mytoplevel %x %y"
    bind $mytoplevel.w.listbox.box <Return> "::scrollbox::edit_item $mytoplevel $edit_method"
    bind $mytoplevel.w.listbox.box <<Delete>> "::scrollbox::delete_item $mytoplevel"

    # <Configure> is called when the user modifies the window
    # We use it to capture resize events, to make sure the
    # currently selected item in the listbox is always visible
    bind $mytoplevel <Configure> "$mytoplevel.w.listbox.box see active"

    # The listbox should expand to fill its containing window
    # the "-fill" option specifies which direction (x, y or both) to fill, while
    # the "-expand" option (false by default) specifies whether the widget
    # should fill

    # All widget interactions can be performed without buttons, but
    # we still need a "New..." button since the currently visible window
    # might be full (even though the user can still expand it)
    ttk::frame $mytoplevel.w.actions
    ttk::button $mytoplevel.w.actions.add_path -text [_ "New..." ] \
        -command "::scrollbox::add_item $mytoplevel $add_method" \
        
    ttk::button $mytoplevel.w.actions.edit_path -text [_ "Edit..." ] \
        -command "::scrollbox::edit_item $mytoplevel $edit_method" \
        
    ttk::button $mytoplevel.w.actions.delete_path -text [_ "Delete" ] \
        -command "::scrollbox::delete_item $mytoplevel" \
        

    $mytoplevel.w.listbox.box activate end
    $mytoplevel.w.listbox.box selection set end
    focus $mytoplevel.w.listbox.box
}
