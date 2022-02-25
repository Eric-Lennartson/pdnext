package require Tk 8.6

# Currently all this script does is load in the pedal ttk files.
# I need to adjust themeing of menus and such to match the themes-plugin
# not sure if I need to have this whole script, I could probably combine
# the two.

# bezier cords
proc redraw_cords {name, blank, op} {
    foreach wind [wm stackorder .] {
        if {[winfo class $wind] eq "PatchWindow"} {
            set canv ${wind}.c
            foreach record [$canv find withtag cord] {
                set tag [lindex [$canv gettags $record] 0]
                set coords [lreplace [$canv coords $tag] 2 end-2]
                ::pdtk_canvas::pdtk_coords {*}$coords $tag $canv
            }
        }
    }
}

trace variable ::curve_cords w redraw_cords
set ::curve_cords 1 ;# bezier cords

set dark  [file join "$::sys_guidir" "pedal" "pedal-dark.tcl"]
set light [file join "$::sys_guidir" "pedal" "pedal-light.tcl"]
source $dark
source $light

ttk::setTheme pedal-light
set theme [ttk::style theme use]
::pdwindow::debug "$theme loaded. Theming pd with $theme!\n"

# Also, it's in the prefs menu rn, but  eventually I want to make a gui dialog, where
# It becomes much easier to create and set this kinda stuff
# (This is also where the font dialog would live)

set ::themeState 1 ;# 1 for light, 0 for dark
proc updateTheme {args} {
    if {$::themeState == 0} {
        ttk::setTheme pedal-dark
    } else {
        ttk::setTheme pedal-light
    }
    foreach wind [wm stackorder .] {
        if {[winfo class $wind] eq "PatchWindow"} {
            set canv ${wind}.c
            ::pdtk_canvas::updateTheme $canv
        } elseif {[winfo class $wind] eq "PdWindow"} {
            ::pdwindow::set_colors
        }
    }
    # ::pdwindow::debug "themeState changed to $::themeState\n"
    # ::pdwindow::debug "theme changed to [ttk::style theme use]\n"
}
trace variable ::themeState w updateTheme
