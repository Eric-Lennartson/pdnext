
package provide pdtk_canvas 0.1

package require pd_bindings

namespace eval ::pdtk_canvas:: {
    namespace export pdtk_canvas_popup
    namespace export pdtk_canvas_editmode
    namespace export pdtk_canvas_getscroll
    namespace export pdtk_canvas_setparents
    namespace export pdtk_canvas_reflecttitle
    namespace export pdtk_canvas_menuclose
}

# store the filename associated with this window,
# so we can use it during menuclose
array set ::pdtk_canvas::::window_fullname {}

# One thing that is tricky to understand is the difference between a Tk
# 'canvas' and a 'canvas' in terms of Pd's implementation.  They are similar,
# but not the same thing.  In Pd code, a 'canvas' is basically a patch, while
# the Tk 'canvas' is the backdrop for drawing everything that is in a patch.
# The Tk 'canvas' is contained in a 'toplevel' window. That window has a Tk
# class of 'PatchWindow'.

# TODO figure out weird frameless window when you open a graph


#TODO: http://wiki.tcl.tk/11502
# MS Windows
#wm geometry . returns contentswidthxcontentsheight+decorationTop+decorationLeftEdge.
#and
#winfo rooty . returns contentsTop
#winfo rootx . returns contentsLeftEdge

if {$::tcl_version < 8.5 || \
        ($::tcl_version == 8.5 && \
             [tk windowingsystem] eq "aqua" && \
             [lindex [split [info patchlevel] "."] 2] < 13) } {
    # fit the geometry onto screen for Tk 8.4,
    # also check for Tk Cocoa backend on macOS which is only stable in 8.5.13+;
    # newer versions of Tk can handle multiple monitors so allow negative pos
    proc pdtk_canvas_wrap_window {x y w h} {
        set width [lindex [wm maxsize .] 0]
        set height [lindex [wm maxsize .] 1]

        if {$w > $width} {
            set w $width
            set x 0
        }
        if {$h > $height} {
            # 30 for window framing
            set h [expr $height - $::menubarsize - $::windowframey]
            set y $::menubarsize
        }

        set x [ expr $x % $width]
        set y [ expr $y % $height]
        if {$x < 0} {set x 0}
        if {$y < 0} {set y 0}

        return [list ${x} ${y} ${w} ${h}]
    }
} {
    proc pdtk_canvas_wrap_window {x y w h} {
        return [list ${x} ${y} ${w} ${h}]
    }
}

# this proc is split out on its own to make it easy to override. This makes it
# easy for people to customize these calculations based on their Window
# Manager, desires, etc.
proc pdtk_canvas_place_window {width height geometry} {
    ::pdwindow::configure_window_offset

    # read back the current geometry +posx+posy into variables
    scan $geometry {%[+]%d%[+]%d} - x - y
    set xywh [pdtk_canvas_wrap_window \
        [expr $x - $::windowframex] [expr $y - $::windowframey] $width $height]
    set x [lindex $xywh 0]
    set y [lindex $xywh 1]
    set w [lindex $xywh 2]
    set h [lindex $xywh 3]
    return [list ${w} ${h} ${w}x${h}+${x}+${y}]
}


#------------------------------------------------------------------------------#
# canvas new/saveas

proc pdtk_canvas_new {mytoplevel width height geometry editable} {
    set l [pdtk_canvas_place_window $width $height $geometry]
    set width [lindex $l 0]
    set height [lindex $l 1]
    set geometry [lindex $l 2]
    set ::undo_actions($mytoplevel) no
    set ::redo_actions($mytoplevel) no

    # release the window grab here so that the new window will
    # properly get the Map and FocusIn events when its created
    ::pdwindow::busyrelease
    # set the loaded array for this new window so things can track state
    set ::loaded($mytoplevel) 0
    toplevel $mytoplevel -width $width -height $height -class PatchWindow
    wm group $mytoplevel .
    $mytoplevel configure -menu $::patch_menubar

    # we have to wait until $mytoplevel exists before we can generate
    # a <<Loading>> event for it, that's why this is here and not in the
    # started_loading_file proc.  Perhaps this doesn't make sense tho
    event generate $mytoplevel <<Loading>>

    wm geometry $mytoplevel $geometry
    wm minsize $mytoplevel $::canvas_minwidth $::canvas_minheight

    set tkcanvas [tkcanvas_name $mytoplevel]
    canvas $tkcanvas -width $width -height $height \
        -highlightthickness 0 -scrollregion [list 0 0 $width $height] \
        -xscrollcommand "$mytoplevel.xscroll set" \
        -yscrollcommand "$mytoplevel.yscroll set"


    set tmpcol [::pdtk_canvas::get_color txt_highlight $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -selectbackground $tmpcol
    }
    set tmpcol [::pdtk_canvas::get_color canvas_fill $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -background $tmpcol
    }
    set tmpcol [::pdtk_canvas::get_color canvas_text_cursor $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -insertbackground $tmpcol
    }
    #in Tk 8.6 the selectforeground is set by the os theme?
    set tmpcol [::pdtk_canvas::get_color txt_highlight_front $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -selectforeground \
        	[::pdtk_canvas::get_color txt_highlight_front $mytoplevel]
    }

    ttk::scrollbar $mytoplevel.xscroll -orient horizontal -command "$tkcanvas xview"
    ttk::scrollbar $mytoplevel.yscroll -orient vertical -command "$tkcanvas yview"
    pack $tkcanvas -side left -expand 1 -fill both

    # for some crazy reason, win32 mousewheel scrolling is in units of
    # 120, and this forces Tk to interpret 120 to mean 1 scroll unit
    if {$::windowingsystem eq "win32"} {
        $tkcanvas configure -xscrollincrement 1 -yscrollincrement 1
    }

    ::pd_bindings::patch_bindings $mytoplevel

    # give focus to the canvas so it gets the events rather than the window
    focus $tkcanvas

    # let the scrollbar logic determine if it should make things scrollable
    set ::xscrollable($tkcanvas) 0
    set ::yscrollable($tkcanvas) 0

    # init patch properties arrays
    set ::editingtext($mytoplevel) 0
    set ::childwindows($mytoplevel) {}

    # this should be at the end so that the window and canvas are all ready
    # before this variable changes.
    set ::editmode($mytoplevel) $editable
}

# if the patch canvas window already exists, then make it come to the front
proc pdtk_canvas_raise {mytoplevel} {
    wm deiconify $mytoplevel
    raise $mytoplevel
    set mycanvas $mytoplevel.c
    focus $mycanvas
}

proc pdtk_canvas_saveas {name initialfile initialdir destroyflag} {
    if { ! [file isdirectory $initialdir]} {set initialdir $::filenewdir}
    set filename [tk_getSaveFile -initialdir $initialdir \
                      -defaultextension .pd -filetypes $::filetypes]
    if {$filename eq ""} return; # they clicked cancel

    set extension [file extension $filename]
    set oldfilename $filename
    set filename [regsub -- "$extension$" $filename [string tolower $extension]]
    if { ! [regexp -- "\.(pd|pat|mxt)$" $filename]} {
        # we need the file extension even on Mac OS X
        set filename $filename.pd
    }
    # test again after downcasing and maybe adding a ".pd" on the end
    if {$filename ne $oldfilename && [file exists $filename]} {
        set answer [tk_messageBox -type okcancel -icon question -default cancel\
                        -message [_ "\"$filename\" already exists. Do you want to replace it?"]]
        if {$answer eq "cancel"} return; # they clicked cancel
    }
    set dirname [file dirname $filename]
    set basename [file tail $filename]
    pdsend "$name savetofile [enquote_path $basename] [enquote_path $dirname] \
 $destroyflag"
    set ::filenewdir $dirname
    # add to recentfiles
    ::pd_guiprefs::update_recentfiles $filename
}

##### ask user Save? Discard? Cancel?, and if so, send a message on to Pd ######
proc ::pdtk_canvas::pdtk_canvas_menuclose {mytoplevel reply_to_pd} {
    raise $mytoplevel
    set filename [lindex [array get ::pdtk_canvas::::window_fullname $mytoplevel] 1]
    set message [format {Do you want to save the changes you made in "%s"?} $filename]
    set answer [tk_messageBox -message $message -type yesnocancel -default "yes" \
                    -parent $mytoplevel -icon question]
    switch -- $answer {
        yes {pdsend "$mytoplevel menusave 1"}
        no {pdsend $reply_to_pd}
        cancel {}
    }
}

#------------------------------------------------------------------------------#
# mouse usage

# TODO put these procs into the pdtk_canvas namespace
proc pdtk_canvas_motion {tkcanvas x y mods} {
    set mytoplevel [winfo toplevel $tkcanvas]
    pdsend "$mytoplevel motion [$tkcanvas canvasx $x] [$tkcanvas canvasy $y] $mods"
}

proc pdtk_canvas_mouse {tkcanvas x y b f} {
    set mytoplevel [winfo toplevel $tkcanvas]
    pdsend "$mytoplevel mouse [$tkcanvas canvasx $x] [$tkcanvas canvasy $y] $b $f"
}

proc pdtk_canvas_mouseup {tkcanvas x y b {f 0}} {
    set mytoplevel [winfo toplevel $tkcanvas]
    pdsend "$mytoplevel mouseup [$tkcanvas canvasx $x] [$tkcanvas canvasy $y] $b $f"
}

proc pdtk_canvas_rightclick {tkcanvas x y b} {
    set mytoplevel [winfo toplevel $tkcanvas]
    pdsend "$mytoplevel mouse [$tkcanvas canvasx $x] [$tkcanvas canvasy $y] $b 8"
}

# on X11, button 2 pastes from X11 clipboard, so simulate normal paste actions
proc pdtk_canvas_clickpaste {tkcanvas x y b} {
    pdtk_canvas_mouse $tkcanvas $x $y $b 0
    pdtk_canvas_mouseup $tkcanvas $x $y $b 0
    if { [catch {set pdtk_pastebuffer [selection get]}] } {
        # no selection... do nothing
    } else {
        for {set i 0} {$i < [string length $pdtk_pastebuffer]} {incr i 1} {
            set cha [string index $pdtk_pastebuffer $i]
            scan $cha %c keynum
            pdsend "[winfo toplevel $tkcanvas] key 1 $keynum 0"
        }
    }
}

#------------------------------------------------------------------------------#
# canvas popup menu

# since there is one popup that is used for all canvas windows, the menu
# -commands use {} quotes so that $::focused_window is interpreted when the
# menu item is called, not when the command is mapped to the menu item.  This
# is the same as the menubar in pd_menus.tcl but the opposite of the 'bind'
# commands in pd_bindings.tcl
proc ::pdtk_canvas::create_popup {} {
    if { ! [winfo exists .popup]} {
        # the popup menu for the canvas
        menu .popup -tearoff false
        .popup add command -label [_ "Properties"] \
            -command {::pdtk_canvas::done_popup $::focused_window 0}
        .popup add command -label [_ "Open"]       \
            -command {::pdtk_canvas::done_popup $::focused_window 1}
        .popup add command -label [_ "Help"]       \
            -command {::pdtk_canvas::done_popup $::focused_window 2}
    }
}

proc ::pdtk_canvas::done_popup {mytoplevel action} {
    pdsend "$mytoplevel done-popup $action $::popup_xcanvas $::popup_ycanvas"
}

proc ::pdtk_canvas::pdtk_canvas_popup {mytoplevel xcanvas ycanvas hasproperties hasopen} {
    set ::popup_xcanvas $xcanvas
    set ::popup_ycanvas $ycanvas
    if {$hasproperties} {
        .popup entryconfigure [_ "Properties"] -state normal
    } else {
        .popup entryconfigure [_ "Properties"] -state disabled
    }
    if {$hasopen} {
        .popup entryconfigure [_ "Open"] -state normal
    } else {
        .popup entryconfigure [_ "Open"] -state disabled
    }
    set tkcanvas [tkcanvas_name $mytoplevel]
    set scrollregion [$tkcanvas cget -scrollregion]
    # get the canvas location that is currently the top left corner in the window
    set left_xview_pix [expr [lindex [$tkcanvas xview] 0] * [lindex $scrollregion 2]]
    set top_yview_pix [expr [lindex [$tkcanvas yview] 0] * [lindex $scrollregion 3]]
    # take the mouse clicks in canvas coords, add the root of the canvas
    # window, and subtract the area that is obscured by scrolling
    set xpopup [expr int($xcanvas + [winfo rootx $tkcanvas] - $left_xview_pix)]
    set ypopup [expr int($ycanvas + [winfo rooty $tkcanvas] - $top_yview_pix)]
    tk_popup .popup $xpopup $ypopup 0
}

if {[tk windowingsystem] eq "aqua" } {
    # I don't know how to move the mouse on OSX, so skip it
    proc ::pdtk_canvas::setmouse {tkcanvas x y} { }
} else {
    proc ::pdtk_canvas::setmouse {tkcanvas x y} {
        # set the mouse to the given position
        # (same coordinate system as reported by pdtk_canvas_motion)
        event generate $tkcanvas <Motion> -warp 1 -x $x -y $y
    }
}

#------------------------------------------------------------------------------#
# procs for when file loading starts/finishes

proc ::pdtk_canvas::started_loading_file {patchname} {
    ::pdwindow::busygrab
}

# things to run when a patch is finished loading.  This is called when
# the OS sends the "Map" event for this window.
proc ::pdtk_canvas::finished_loading_file {mytoplevel} {
    # ::pdwindow::busyrelease is in pdtk_canvas_new so that the grab
    # is released before the new toplevel window gets created.
    # Otherwise the grab blocks the new window from getting the
    # FocusIn event on creation.

    # set editmode to make sure the menu item is in the right state
    pdtk_canvas_editmode $mytoplevel $::editmode($mytoplevel)
    set ::loaded($mytoplevel) 1
    # send the virtual events now that everything is loaded
    event generate $mytoplevel <<Loaded>>
}

#------------------------------------------------------------------------------#
# procs for canvas events

# check or uncheck the "edit" menu item
proc ::pdtk_canvas::pdtk_canvas_editmode {mytoplevel state} {
    set ::editmode_button $state
    set ::editmode($mytoplevel) $state
    event generate $mytoplevel <<EditMode>>
}

# message from Pd to update the currently available undo/redo action
proc pdtk_undomenu {mytoplevel undoaction redoaction} {
    set ::undo_actions($mytoplevel) $undoaction
    set ::redo_actions($mytoplevel) $redoaction
    if {$mytoplevel ne "nobody"} {
        ::pd_menus::update_undo_on_menu $mytoplevel $undoaction $redoaction
    }
}

# This proc configures the scrollbars whenever anything relevant has
# been updated.  It should always receive a tkcanvas, which is then
# used to generate the mytoplevel, needed to address the scrollbars.
proc ::pdtk_canvas::pdtk_canvas_getscroll {tkcanvas} {
    if {! [winfo exists $tkcanvas]} {
        return
    }
    set mytoplevel [winfo toplevel $tkcanvas]
    set height [winfo height $tkcanvas]
    set width [winfo width $tkcanvas]

    set bbox [$tkcanvas bbox all]
    if {$bbox eq "" || [llength $bbox] != 4} {return}
    set xupperleft [lindex $bbox 0]
    set yupperleft [lindex $bbox 1]
    if {$xupperleft > 0} {set xupperleft 0}
    if {$yupperleft > 0} {set yupperleft 0}
    set xlowerright [lindex $bbox 2]
    set ylowerright [lindex $bbox 3]
    if {$xlowerright < $width} {set xlowerright $width}
    if {$ylowerright < $height} {set ylowerright $height}
    set scrollregion [concat $xupperleft $yupperleft $xlowerright $ylowerright]
    $tkcanvas configure -scrollregion $scrollregion
    # X scrollbar
    if {[lindex [$tkcanvas xview] 0] == 0.0 && [lindex [$tkcanvas xview] 1] == 1.0} {
        set ::xscrollable($tkcanvas) 0
        pack forget $mytoplevel.xscroll
    } else {
        set ::xscrollable($tkcanvas) 1
        pack $mytoplevel.xscroll -side bottom -fill x -before $tkcanvas
    }
    # Y scrollbar, it gets touchy at the limit, so say > 0.995
    if {[lindex [$tkcanvas yview] 0] == 0.0 && [lindex [$tkcanvas yview] 1] > 0.995} {
        set ::yscrollable($tkcanvas) 0
        pack forget $mytoplevel.yscroll
    } else {
        set ::yscrollable($tkcanvas) 1
        pack $mytoplevel.yscroll -side right -fill y -before $tkcanvas
    }
}

proc ::pdtk_canvas::scroll {tkcanvas axis amount} {
    if {$axis eq "x" && $::xscrollable($tkcanvas) == 1} {
        $tkcanvas xview scroll [expr {- ($amount)}] units
    }
    if {$axis eq "y" && $::yscrollable($tkcanvas) == 1} {
        $tkcanvas yview scroll [expr {- ($amount)}] units
    }
}

#------------------------------------------------------------------------------#
# get patch window child/parent relationships

# add a child window ID to the list of children, if it isn't already there
proc ::pdtk_canvas::addchild {mytoplevel child} {
    # if either ::childwindows($mytoplevel) does not exist, or $child does not
    # exist inside of the ::childwindows($mytoplevel list
    if { [lsearch -exact [array names ::childwindows $mytoplevel]] == -1 \
             || [lsearch -exact $::childwindows($mytoplevel) $child] == -1} {
        set ::childwindows($mytoplevel) [lappend ::childwindows($mytoplevel) $child]
    }
}

# receive a list of all my parent windows from 'pd'
proc ::pdtk_canvas::pdtk_canvas_setparents {mytoplevel args} {
    set ::parentwindows($mytoplevel) $args
    foreach parent $args {
        addchild $parent $mytoplevel
    }
}

# receive information for setting the info the the title bar of the window
proc ::pdtk_canvas::pdtk_canvas_reflecttitle {mytoplevel \
                                              path name arguments dirty} {
    set ::windowname($mytoplevel) $name
    set ::pdtk_canvas::::window_fullname($mytoplevel) "$path/$name"
    if {$::windowingsystem eq "aqua"} {
        wm attributes $mytoplevel -modified $dirty
        if {[file exists "$path/$name"]} {
            # for some reason -titlepath can still fail so just catch it
            if [catch {wm attributes $mytoplevel -titlepath "$path/$name"}] {
                wm title $mytoplevel "$path/$name"
            }
        }
        wm title $mytoplevel "$name$arguments"
    } else {
        if {$dirty} {set dirtychar "*"} else {set dirtychar " "}
        wm title $mytoplevel "$name$dirtychar$arguments - $path"
    }
}

#------------------------------------------------------------------------------#
# get color value for pd
proc ::pdtk_canvas::get_color {type {window 0}} {
    if {$::themeState} {
        return $::lightTheme($type)
    } else {
        return $::darkTheme($type)
    }
}

proc ::pdtk_canvas::updateTheme {mytoplevel} {
    set tkcanvas $mytoplevel
    set tmpcol [::pdtk_canvas::get_color txt_highlight $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -selectbackground $tmpcol
    }
    set tmpcol [::pdtk_canvas::get_color canvas_fill $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -background $tmpcol
    }
    set tmpcol [::pdtk_canvas::get_color canvas_text_cursor $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -insertbackground $tmpcol
    }
    #in Tk 8.6 the selectforeground is set by the os theme?
    set tmpcol [::pdtk_canvas::get_color txt_highlight_front $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -selectforeground \
        	[::pdtk_canvas::get_color txt_highlight_front $mytoplevel]
    }
}

# get color value for pd
proc ::pdtk_canvas::get_color {type {window 0}} {
    return $::pd_colors($type)
}

proc ::pdtk_canvas::updateTheme {mytoplevel} {
    set tkcanvas $mytoplevel
    set tmpcol [::pdtk_canvas::get_color txt_highlight $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -selectbackground $tmpcol
    }
    set tmpcol [::pdtk_canvas::get_color canvas_fill $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -background $tmpcol
    }
    set tmpcol [::pdtk_canvas::get_color canvas_text_cursor $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -insertbackground $tmpcol
    }
    #in Tk 8.6 the selectforeground is set by the os theme?
    set tmpcol [::pdtk_canvas::get_color txt_highlight_front $mytoplevel]
    if {$tmpcol ne ""} {
        $tkcanvas configure -selectforeground \
        	[::pdtk_canvas::get_color txt_highlight_front $mytoplevel]
    }
}


proc ::pdtk_canvas::pdtk_connect {x1 y1 x2 y2 width tags wind col} {
# from pd-l2ork
	if {$::curve_cords} {
		set ymax 0;
		set halfx [expr {($x2 - $x1)/2}]
		set halfy [expr {($y2 - $y1)/2}]
		set yoff [expr {abs($halfy)}]
		if {$halfy >= 0} {
			# second object is below the first
			if {abs($halfx) <= 10} {
				set ymax [expr {abs($halfy * pow($halfx/10.0, 2))}]
				if {$ymax > 10} {
					set ymax 10
				}
			} else {
				set ymax 10
			}
		} else {
			# second object is above the first
			set ymax 20
		}
		if {$yoff > $ymax} {
			set yoff $ymax;
		}
		${wind}.c create line $x1 $y1 $x1 [expr {$y1 + $yoff}] \
			[expr {$x1 + $halfx}] [expr {$y1 + $halfy}] $x2 \
			[expr {$y2 - $yoff}] $x2 $y2 -smooth 1 \
			-width $width -tags $tags -fill [get_color $col $wind]
	} else {
		# have to set smooth and splinesteps in case it changes
		${wind}.c create line $x1 $y1 $x2 $y2 -width $width -tags $tags \
			-smooth 1 -fill [get_color $col $wind]
	}
}

# doesn't this function basically duplicate
# the majority of the above code???

proc ::pdtk_canvas::pdtk_coords {x1 y1 x2 y2 tag canv} {
	# from pd-l2ork
	if {$::curve_cords} {
		set ymax 0;
		set halfx [expr {($x2 - $x1)/2}]
		set halfy [expr {($y2 - $y1)/2}]
		set yoff [expr {abs($halfy)}]
		if {$halfy >= 0} {
			# second object is below the first
			if {abs($halfx) <= 10} {
				set ymax [expr {abs($halfy * pow($halfx/10.0, 2))}]
				if {$ymax > 10} {
					set ymax 10
				}
			} else {
				set ymax 10
			}
		} else {
			# second object is above the first
			set ymax 20
		}
		if {$yoff > $ymax} {
			set yoff $ymax;
		}
		${canv} coords $tag $x1 $y1 $x1 [expr {$y1 + $yoff}] \
			[expr {$x1 + $halfx}] [expr {$y1 + $halfy}] $x2 \
			[expr {$y2 - $yoff}] $x2 $y2
	} else {
		${canv} coords $tag $x1 $y1 $x2 $y2
	}
}
