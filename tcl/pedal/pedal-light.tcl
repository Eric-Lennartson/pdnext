# This software is copyrighted by the Regents of the University of
# California, Sun Microsystems, Inc., Scriptics Corporation, and other
# parties.
# Original version available under BSD-like license as in LICENSE.ORIG

# Modified by RedFantom
# Copyright (C) 2018 RedFantom
# Modified version available under GNU GPLv3 only

namespace eval ttk::theme::pedal-light {

    package provide ttk::theme::pedal-light 0.1

    proc LoadImages {imgdir {patterns {*.gif}}} {
        foreach pattern $patterns {
            foreach file [glob -directory $imgdir $pattern] {
                set img [file tail [file rootname $file]]
                if {![info exists images($img)]} {
                    set images($img) [image create photo -file $file]
                }
            }
        }
        return [array get images]
    }

    variable I
    array set I [LoadImages \
                     [file join [file dirname [info script]] pedal-light] *.gif]
    
    variable colors

    array set colors {
            bg0            "#F3F1EB"
            bg1            "#EEECE3"
            bg2            "#DCD6C5"
            text           "#1E5684"
            entryText      "#6F249B"
            insert         "#2B2B2B"
            disabled       "#c2baa1"
            progressbarbg  "#c2baa1"
            border         "#AAAAAA"
            checklight     "#EAE6DC"
            -lighter        "#32302f"
            -dark           "#32302f"
            -darker         "#c3bab0"
            -darkest        "#a89c91"
            selectfg       "#AE7CCB"
            -selectfg       "#32302f"
            -disabledfg     "#9e928a"
            -tabbg1         "#68948a"
            -tabbg2         "#7daea3"
            -tabborder      "#000000"
    }

    #PhG: change fonts... should not fail if font is not there!
    font configure TkDefaultFont -family Ubuntu -size 11

    ttk::style theme create pedal-light -parent clam -settings {

        ttk::style configure . \
            -borderwidth        1 \
            -background         $colors(bg0) \
            -foreground         $colors(text) \
            -bordercolor        $colors(border) \
            -darkcolor          $colors(border) \
            -lightcolor         $colors(border) \
            -troughcolor        $colors(bg0) \
            -selectforeground   $colors(-selectfg) \
            -selectbackground   $colors(selectfg) \
            -font               TkDefaultFont \
            ;

        ttk::style map . \
            -background [list disabled $colors(bg0) \
                             active $colors(-lighter)] \
            -foreground [list disabled $colors(-disabledfg)] \
            -selectbackground [list !focus $colors(-darker)] \
            -selectforeground [list !focus white] \
            ;


#        ttk::style configure Frame.border -relief groove

        ## Treeview.
        #
        ttk::style element create Treeheading.cell image \
            [list $I(tree-n) \
                 selected $I(tree-p) \
                 disabled $I(tree-d) \
                 pressed $I(tree-p) \
                 active $I(tree-h) \
                ] \
            -border 4 -sticky ew
        # Older Tk versions
        #ttk::style configure Treeview -fieldbackground white
        ttk::style configure Row -background "#efefef"
        ttk::style map Row -background [list \
            {focus selected} "#71869e" \
            selected "#969286" \
            alternate white]
        ttk::style map Item -foreground [list selected white]
        ttk::style map Cell -foreground [list selected white]
        # Newer Tk versions
        ttk::style map Treeview \
            -background [list selected $colors(selectfg)] \
            -foreground [list selected $colors(-selectfg)]


        ## Buttons.
        #
        ttk::style configure TButton -width 6 -anchor center
        ttk::style configure TButton -padding {10 0}
        ttk::style layout TButton {
            Button.focus -children {
                Button.button -children {
                    Button.padding -children {
                        Button.label
                    }
                }
            }
        }
#PhG = OK! except selection box
        ttk::style element create Button.button image \
            [list $I(button-n) \
                 pressed $I(button-p) \
                 {selected active} $I(button-sa) \
                 selected $I(button-s) \
                 active $I(button-a) \
                 disabled $I(button-d) \
                ] \
            -border 8 -sticky ew

        ttk::style configure TButton \
            -foreground $colors(text) \
            -background $colors(bg0)
        ttk::style map TButton -foreground [list active "#292828"]
        ttk::style map TButton -background [list active $colors(bg0)]

        ## Checkbuttons.
        #
        ttk::style element create Checkbutton.indicator image \
            [list $I(check-nu) \
                 {disabled selected} $I(check-dc) \
                 disabled $I(check-du) \
                 {pressed selected} $I(check-nc) \
                 pressed $I(check-nu) \
                 {active selected} $I(check-nc) \
                 active $I(check-nu) \
                 selected $I(check-nc) ] \
            -width 24 -sticky w

        ttk::style map TCheckbutton -background [list active $colors(checklight)]
        ttk::style configure TCheckbutton -padding 1 -foreground $colors(text) \
            -background $colors(bg0)


        ## Radiobuttons.
        #
        ttk::style element create Radiobutton.indicator image \
             [list $I(radio-nu) \
                  {disabled selected} $I(radio-dc) \
                  disabled $I(radio-du) \
                  {pressed selected} $I(radio-nc) \
                  pressed $I(radio-nu) \
                  {active selected} $I(radio-nc) \
                  active $I(radio-nu) \
                  selected $I(radio-nc) ] \
            -width 17 -sticky w

        ttk::style map TRadiobutton -background [list active $colors(checklight)]
        ttk::style configure TRadiobutton -padding "2 1" -foreground $colors(text)


        ## Menubuttons.
        #
        #ttk::style configure TMenubutton -relief raised -padding {10 2}
# 	ttk::style element create Menubutton.border image $I(toolbutton-n) \
# 	    -map [list \
#                       pressed $I(toolbutton-p) \
#                       selected $I(toolbutton-p) \
#                       active $I(toolbutton-a) \
#                       disabled $I(toolbutton-n)] \
# 	    -border {4 7 4 7} -sticky nsew

        ttk::style element create Menubutton.border image \
             [list $I(button-n) \
                  selected $I(button-p) \
                  disabled $I(button-d) \
                  active $I(button-a) \
                 ] \
            -border 4 -sticky ew


        ## Toolbar buttons.
        #
###PhG added
ttk::style configure Toolbutton -anchor center
        ttk::style configure Toolbutton -padding -5 -relief flat
        ttk::style configure Toolbutton.label -padding 0 -relief flat

        ttk::style element create Toolbutton.border image \
            [list $I(blank) \
                 pressed $I(toolbutton-p) \
                 {selected active} $I(toolbutton-pa) \
                 selected $I(toolbutton-p) \
                 active $I(toolbutton-a) \
                 disabled $I(blank)] \
            -border 11 -sticky nsew


        ## Entry widgets.
        #
        ttk::style configure TEntry -padding 1 -insertwidth 1 \
            -fieldbackground $colors(bg2) -bordercolor $colors(bg0) \
            -darkcolor   $colors(bg0) -lightcolor  $colors(bg0) \
            -foreground  $colors(entryText) -insertcolor $colors(insert)

        ttk::style map TEntry \
            -fieldbackground [list readonly $colors(disabled)] \
            -bordercolor     [list focus $colors(selectfg)] \
            -lightcolor      [list focus $colors(selectfg)] \
            -darkcolor       [list focus $colors(selectfg)]

        ## Combobox.
        #
        ttk::style configure TCombobox \
            -background $colors(bg0) -foreground $colors(text) \
            -selectbackground "#7c6f64" -selectforeground "#7daea3" \
            -insertcolor $colors(insert)
        # good old option add for the dropdown .......
        option add *TCombobox*Listbox.background $colors(bg2)
        option add *TCombobox*Listbox.foreground $colors(text)
        option add *TCombobox*Listbox.selectBackground "#7c6f64"
        option add *TCombobox*Listbox.selectForeground "#7daea3"

        ttk::style element create Combobox.downarrow image \
            [list $I(comboarrow-n) \
                 disabled $I(comboarrow-d) \
                 pressed $I(comboarrow-p) \
                 active $I(comboarrow-a) \
                ] \
            -border 1 -sticky {}

        ttk::style element create Combobox.field image \
            [list $I(combo-n) \
                 {readonly disabled} $I(combo-rd) \
                 {readonly pressed} $I(combo-rp) \
                 {readonly focus} $I(combo-rf) \
                 readonly $I(combo-rn) \
                ] \
            -border 4 -sticky ew


        ## Notebooks.
        #
#         ttk::style element create tab image $I(tab-a) -border {2 2 2 0} \
#             -map [list selected $I(tab-n)]

        ttk::style configure TNotebook.Tab -padding {6 2 6 2}
        ttk::style map TNotebook.Tab \
            -padding [list selected {6 4 6 2}] \
            -background  [list selected $colors(-tabbg2) {} $colors(-tabbg1)] \
            -lightcolor  [list selected $colors(-lighter) {} $colors(-dark)] \
            -bordercolor [list selected $colors(-darkest) {} $colors(-tabborder)] \
            ;

        ## Frames.
        #
        ttk::style configure TFrame -background $colors(bg0)

        ## Labelframes.
        #
        ttk::style configure TLabelframe \
            -borderwidth 2 -relief groove \
            -background $colors(bg0) -bordercolor $colors(border)
        ttk::style configure TLabelframe.Label \
            -background $colors(bg0) -foreground $colors(text)

        ## Labels.
        #
        ttk::style configure TLabel -background $colors(bg0) -foreground $colors(text)

        ## Scrollbars.
        #
        ttk::style layout Vertical.TScrollbar {
            Scrollbar.trough -sticky ns -children {
                Scrollbar.uparrow -side top
                Scrollbar.downarrow -side bottom
                Vertical.Scrollbar.thumb -side top -expand true -sticky ns
            }
        }

        ttk::style layout Horizontal.TScrollbar {
            Scrollbar.trough -sticky we -children {
                Scrollbar.leftarrow -side left
                Scrollbar.rightarrow -side right
                Horizontal.Scrollbar.thumb -side left -expand true -sticky we
            }
        }

        ttk::style element create Horizontal.Scrollbar.thumb image \
            [list $I(sbthumb-hn) \
                 disabled $I(sbthumb-hd) \
                 pressed $I(sbthumb-ha) \
                 active $I(sbthumb-ha)] \
            -border 3

        ttk::style element create Vertical.Scrollbar.thumb image \
            [list $I(sbthumb-vn) \
                 disabled $I(sbthumb-vd) \
                 pressed $I(sbthumb-va) \
                 active $I(sbthumb-va)] \
            -border 3

        foreach dir {up down left right} {
            ttk::style element create ${dir}arrow image \
                [list $I(arrow${dir}-n) \
                     disabled $I(arrow${dir}-d) \
                     pressed $I(arrow${dir}-p) \
                     active $I(arrow${dir}-a)] \
                -border 1 -sticky {}
        }

        ttk::style configure TScrollbar -bordercolor $colors(bg0)


        ## Scales.
        #
        ttk::style element create Scale.slider image \
            [list $I(scale-hn) \
                 disabled $I(scale-hd) \
                 active $I(scale-ha) \
                ]

        ttk::style element create Scale.trough image $I(scaletrough-h) \
            -border 2 -sticky ew -padding 0

        ttk::style element create Vertical.Scale.slider image \
            [list $I(scale-vn) \
                 disabled $I(scale-vd) \
                 active $I(scale-va) \
                ]
        ttk::style element create Vertical.Scale.trough image $I(scaletrough-v) \
            -border 2 -sticky ns -padding 0

        ttk::style configure TScale -bordercolor $colors(bg0)


        ## Progressbar.
        #
        ttk::style element create Horizontal.Progressbar.pbar image $I(progress-h) \
            -border {5 2 5 1} -padding 1
        ttk::style element create Vertical.Progressbar.pbar image $I(progress-v) \
            -border {5 2 5 1} -padding 1

        ttk::style configure TProgressbar \
            -bordercolor $colors(border) \
            -background $colors(progressbarbg)


        ## Statusbar parts.
        #
        ttk::style element create sizegrip image $I(sizegrip)


        ## Paned window parts.
        #
#         ttk::style element create hsash image $I(hseparator-n) -border {2 0} \
#             -map [list {active !disabled} $I(hseparator-a)]
#         ttk::style element create vsash image $I(vseparator-n) -border {0 2} \
#             -map [list {active !disabled} $I(vseparator-a)]

        ttk::style configure Sash -sashthickness 6 -gripcount 16


        ## Separator.
        #
        #ttk::style element create separator image $I(sep-h)
        #ttk::style element create hseparator image $I(sep-h)
        #ttk::style element create vseparator image $I(sep-v)

    }
}

