# TODO this code is very unstable and breaks easily,
# This is mainly because of the terrible global variable thing
# remove it

package provide dialog_iemgui 0.1

namespace eval ::dialog_iemgui:: {
    variable define_min_flashhold 50
    variable define_min_flashbreak 10
    variable define_min_fontsize 4

    namespace export pdtk_iemgui_dialog
}

proc ::dialog_iemgui::clampDimensions {mytoplevel} {
    set vid [string trimleft $mytoplevel .]
    set w $mytoplevel

    set width [concat iemgui_wdt_$vid]
    global $width
    set minWidth [concat iemgui_min_wdt_$vid]
    global $minWidth
    set height [concat iemgui_hgt_$vid]
    global $height
    set minHeight [concat iemgui_min_hgt_$vid]
    global $minHeight

    if {$::iemgui_type == "Number"} {
        if {[eval concat $$width] < [eval concat $$minWidth]} {
            set $width [eval concat $$minWidth]
            $::snb.widthEntry configure -textvariable $width
        }
        if {[eval concat $$height] < [eval concat $$minHeight]} {
            set $height [eval concat $$minHeight]
            $::snb.heightEntry configure -textvariable $height
        }
    } 
    if {$::iemgui_type == "Slider"} {
        if {[eval concat $$width] < [eval concat $$minWidth]} {
            set $width [eval concat $$minWidth]
            $::snb.sizeAndLimits.widthEntry configure -textvariable $width
        }
        if {[eval concat $$height] < [eval concat $$minHeight]} {
            set $height [eval concat $$minHeight]
            $::snb.sizeAndLimits.heightEntry configure -textvariable $height
        }
    } 

}

# WARN isn't called for sliders, should it be?
proc ::dialog_iemgui::clampLogHeight {mytoplevel} {
    set vid [string trimleft $mytoplevel .]
    set w $mytoplevel
    set snb $::w.sizeAndBehavior

    set logHeight [concat iemgui_num_$vid]
    global $logHeight

    if {[eval concat $$logHeight] > 2000} {
        set $logHeight 2000
        $::snb.logEntry configure -textvariable $logHeight
    }
    if {[eval concat $$logHeight] < 1} {
        set $logHeight 1
        $::snb.logEntry configure -textvariable $logHeight
    }
}

# todo do I need to touch this? (I think it's for bang)
proc ::dialog_iemgui::sched_rng {mytoplevel} {
    set vid [string trimleft $mytoplevel .]
    set w $mytoplevel
    set snb $::w.sizeAndBehavior

    set minRange [concat iemgui_min_rng_$vid]
    global $minRange
    set maxRange [concat iemgui_max_rng_$vid]
    global $maxRange
    set var_iemgui_rng_sch [concat iemgui_rng_sch_$vid]
    global $var_iemgui_rng_sch

    variable define_min_flashhold
    variable define_min_flashbreak

    if {[eval concat $$var_iemgui_rng_sch] == 2} {
        if {[eval concat $$maxRange] < [eval concat $$minRange]} {
            set hhh [eval concat $$minRange]
            set $minRange [eval concat $$maxRange]
            set $maxRange $hhh
            $::snb.maxEntry configure -textvariable $maxRange
            $::snb.minEntry configure -textvariable $minRange }
        if {[eval concat $$maxRange] < $define_min_flashhold} {
            set $maxRange $define_min_flashhold
            $::snb.maxEntry configure -textvariable $maxRange
        }
        if {[eval concat $$minRange] < $define_min_flashbreak} {
            set $minRange $define_min_flashbreak
            $::snb.minEntry configure -textvariable $minRange
        }
    }
    if {[eval concat $$var_iemgui_rng_sch] == 1} {
        if {[eval concat $$minRange] == 0.0} {
            set $minRange 1.0
            $::snb.minEntry configure -textvariable $minRange
        }
    }
}

proc ::dialog_iemgui::verifyRange {mytoplevel} {
    set vid [string trimleft $mytoplevel .]
    set w $mytoplevel
    set snb $::w.sizeAndBehavior

    set minRange [concat iemgui_min_rng_$vid]
    global $minRange
    set maxRange [concat iemgui_max_rng_$vid]
    global $maxRange
    set linLogState [concat iemgui_lin0_log1_$vid]
    global $linLogState

    if {[eval concat $$linLogState] == 1} {
        if {[eval concat $$maxRange] == 0.0 && [eval concat $$minRange] == 0.0} {
            set $maxRange 1.0
            if {$::iemgui_type == "Slider"} {
                $::snb.sizeAndLimits.maxEntry configure -textvariable $maxRange
            } elseif {$::iemgui_type == "Number"} {
                $::snb.maxEntry configure -textvariable $maxRange
            }
        }
        if {[eval concat $$maxRange] > 0} {
            if {[eval concat $$minRange] <= 0} {
                set $minRange [expr [eval concat $$maxRange] * 0.01]
                if {$::iemgui_type == "Slider"} {
                    $::snb.sizeAndLimits.minEntry configure -textvariable $minRange
                } elseif {$::iemgui_type == "Number"} {
                    $::snb.minEntry configure -textvariable $minRange
                }
            }
        } else {
            if {[eval concat $$minRange] > 0} {
                set $maxRange [expr [eval concat $$minRange] * 0.01]
                if {$::iemgui_type == "Slider"} {
                    $::snb.sizeAndLimits.maxEntry configure -textvariable $maxRange
                }  elseif {$::iemgui_type == "Number"} {
                    $::snb.maxEntry configure -textvariable $maxRange
                }
            }
        }
    }
}

# todo remove bug when entering numbers to low, 
# also clamp fontsize from being to high
proc ::dialog_iemgui::clampFontSize {mytoplevel} {
    set vid [string trimleft $mytoplevel .]

    set fontSize [concat iemgui_gn_fs_$vid]
    global $fontSize

    variable define_min_fontsize

    if {[eval concat $$fontSize] < $define_min_fontsize} {
        set $fontSize $define_min_fontsize
        $mytoplevel.label.fs_ent configure -textvariable $fontSize
    }
}

# Color Stuff
    proc ::dialog_iemgui::setColorPreview {mytoplevel} {
        set vid [string trimleft $mytoplevel .]

        set bgColor [concat iemgui_bcol_$vid]
        global $bgColor
        set fgColor [concat iemgui_fcol_$vid]
        global $fgColor
        set lblColor [concat iemgui_lcol_$vid]
        global $lblColor

        #for OSX live updates
        if {$::windowingsystem eq "aqua"} {
            ::dialog_iemgui::apply_and_rebind_return $mytoplevel
        }
    }

    proc ::dialog_iemgui::preset_col {mytoplevel presetcol} {
        set vid [string trimleft $mytoplevel .]

        set bgColor [concat iemgui_bcol_$vid]
        global $bgColor
        set fgColor [concat iemgui_fcol_$vid]
        global $fgColor
        set lblColor [concat iemgui_lcol_$vid]
        global $lblColor

        set $bgColor $presetcol
        set $fgColor $presetcol
        set $lblColor $presetcol
        ::dialog_iemgui::setColorPreview $mytoplevel
    }

    proc ::dialog_iemgui::chooseBgColor {mytoplevel} {
        set vid [string trimleft $mytoplevel .]
        set bgColor [concat iemgui_bcol_$vid]
        global $bgColor
        set $bgColor [eval concat $$bgColor]
        set helpstring [tk_chooseColor -title "Background color" -initialcolor [eval concat $$bgColor]]
        if { $helpstring ne "" } { set $bgColor $helpstring }
        ttk::style configure bg.TFrame -background [eval concat $$bgColor]
        ::dialog_iemgui::setColorPreview $mytoplevel
    }
    proc ::dialog_iemgui::chooseFgColor {mytoplevel} {
        set vid [string trimleft $mytoplevel .]
        set fgColor [concat iemgui_fcol_$vid]
        global $fgColor
        set $fgColor [eval concat $$fgColor]
        set helpstring [tk_chooseColor -title "Foreground color" -initialcolor [eval concat $$fgColor]]
        if { $helpstring ne "" } { set $fgColor $helpstring }
        ttk::style configure fg.TFrame -background [eval concat $$fgColor]
        ::dialog_iemgui::setColorPreview $mytoplevel
    }
    proc ::dialog_iemgui::chooseLblColor {mytoplevel} {
        set vid [string trimleft $mytoplevel .]
        set lblColor [concat iemgui_lcol_$vid]
        global $lblColor
        set $lblColor [eval concat $$lblColor]
        set helpstring [tk_chooseColor -title [_ "Label color"] -initialcolor [eval concat $$lblColor]]
        if { $helpstring ne "" } { set $lblColor $helpstring }
        ttk::style configure lbl.TFrame -background [eval concat $$lblColor]
        ::dialog_iemgui::setColorPreview $mytoplevel
    }

proc ::dialog_iemgui::linLog {mytoplevel} {
    set vid [string trimleft $mytoplevel .]

    # getting the linlog state
    set linLogState [concat iemgui_lin0_log1_$vid]
    global $linLogState

    ::dialog_iemgui::sched_rng $mytoplevel

    # todo this is kinda wonky, possible improvements?
    if {$::iemgui_type == "Slider"} {
        set $linLogState $::sliderLinLogState
        if {$::sliderLinLogState == 1} {
            ::dialog_iemgui::verifyRange $mytoplevel
            ::dialog_iemgui::sched_rng $mytoplevel ;# I don't know what this function does
        }
    } 
    if {$::iemgui_type == "Number"} {
        set $linLogState $::nbxLinLogState
        if {$::nbxLinLogState == 1} {
            ::dialog_iemgui::verifyRange $mytoplevel
            ::dialog_iemgui::sched_rng $mytoplevel
        }
    }
}

proc ::dialog_iemgui::setVUMeterScale {mytoplevel} {
    set vid [string trimleft $mytoplevel .]

    # getting the linlog state, which is the toggle for the scale for some 
    # dumbass reason
    set linLogState [concat iemgui_lin0_log1_$vid]
    global $linLogState
    set $linLogState $::showScale
}

proc ::dialog_iemgui::setFont {mytoplevel} {
    set vid [string trimleft $mytoplevel .]
    set fontType [concat iemgui_gn_f_$vid]
    global $fontType

    # this is terrible, to remove it I'll have to change the iemgui C source code
    array set fontTypeAsInt {
        "Menlo" 0
        "Helvetica" 1
        "Times" 2
    }
    set $fontType $fontTypeAsInt($::fontType)

    set current_font $::fontType
    $::w.windowFrame.label.nameEntry configure -font "{$current_font} 14 $::font_weight"
}

proc ::dialog_iemgui::setInitState {mytoplevel} {
    set vid [string trimleft $mytoplevel .]
    set initState [concat iemgui_loadbang_$vid]
    global $initState

    # this is kinda dumb, and might not even be the issue
    # todo see if I can remove this
    switch $::iemgui_type {
        "Toggle" {
            set $initState $::tglInit
        }
        "Radio" {
            set $initState $::radioInit
        }
        "Slider" {
            set $initState $::sliderInit
        }
        "Number" {
            set $initState $::nbxInit
        }
    }
}

proc ::dialog_iemgui::onClick {mytoplevel} {
    set vid [string trimleft $mytoplevel .]
    set onClickToggle [concat iemgui_steady_$vid]
    global $onClickToggle

    if {$::onClickState == 1} {
        set $onClickToggle 1
        set ::onClickText "Steady"
    } else {
        set $onClickToggle 0
        set ::onClickText "Jump"
    }
}

proc ::dialog_iemgui::apply {mytoplevel} {
    set vid [string trimleft $mytoplevel .]

    set width [concat iemgui_wdt_$vid]
    global $width
    set minWidth [concat iemgui_min_wdt_$vid]
    global $minWidth
    set height [concat iemgui_hgt_$vid]
    global $height
    set minHeight [concat iemgui_min_hgt_$vid]
    global $minHeight
    set minRange [concat iemgui_min_rng_$vid]
    global $minRange
    set maxRange [concat iemgui_max_rng_$vid]
    global $maxRange
    set linLogState [concat iemgui_lin0_log1_$vid]
    global $linLogState
    set initState [concat iemgui_loadbang_$vid]
    global $initState
    set logHeight [concat iemgui_num_$vid]
    global $logHeight
    set onClickToggle [concat iemgui_steady_$vid]
    global $onClickToggle
    set sndSym [concat iemgui_snd_$vid]
    global $sndSym
    set rcvSym [concat iemgui_rcv_$vid]
    global $rcvSym
    set guiName [concat iemgui_gui_nam_$vid]
    global $guiName
    set fontXPos [concat iemgui_gn_dx_$vid]
    global $fontXPos
    set fontYPos [concat iemgui_gn_dy_$vid]
    global $fontYPos
    set fontType [concat iemgui_gn_f_$vid]
    global $fontType
    set fontSize [concat iemgui_gn_fs_$vid]
    global $fontSize
    set bgColor [concat iemgui_bcol_$vid]
    global $bgColor
    set fgColor [concat iemgui_fcol_$vid]
    global $fgColor
    set lblColor [concat iemgui_lcol_$vid]
    global $lblColor

    ::dialog_iemgui::clampDimensions $mytoplevel
    if {$::iemgui_type == "Number"} {
        ::dialog_iemgui::clampLogHeight $mytoplevel
    }
    ::dialog_iemgui::sched_rng $mytoplevel
    ::dialog_iemgui::verifyRange $mytoplevel
    ::dialog_iemgui::sched_rng $mytoplevel ;# I don't even wanna know why this is getting called twice
    ::dialog_iemgui::clampFontSize $mytoplevel

    if {[eval concat $$sndSym] == ""} {set hhhsnd "empty"} else {set hhhsnd [eval concat $$sndSym]}
    if {[eval concat $$rcvSym] == ""} {set hhhrcv "empty"} else {set hhhrcv [eval concat $$rcvSym]}
    if {[eval concat $$guiName] == ""} {set hhhgui_nam "empty"
    } else {
        set hhhgui_nam [eval concat $$guiName]}

    if {[string index $hhhsnd 0] == "$"} {
        set hhhsnd [string replace $hhhsnd 0 0 #] }
    if {[string index $hhhrcv 0] == "$"} {
        set hhhrcv [string replace $hhhrcv 0 0 #] }
    if {[string index $hhhgui_nam 0] == "$"} {
        set hhhgui_nam [string replace $hhhgui_nam 0 0 #] }

    set hhhsnd [unspace_text $hhhsnd]
    set hhhrcv [unspace_text $hhhrcv]
    set hhhgui_nam [unspace_text $hhhgui_nam]

    # make sure the offset boxes have a value
    if {[eval concat $$fontXPos] eq ""} {set $fontXPos 0}
    if {[eval concat $$fontYPos] eq ""} {set $fontYPos 0}

    pdsend  [concat $mytoplevel dialog \
            [eval concat $$width] \
            [eval concat $$height] \
            [eval concat $$minRange] \
            [eval concat $$maxRange] \
            [eval concat $$linLogState] \
            [eval concat $$initState] \
            [eval concat $$logHeight] \
            $hhhsnd \
            $hhhrcv \
            $hhhgui_nam \
            [eval concat $$fontXPos] \
            [eval concat $$fontYPos] \
            [eval concat $$fontType] \
            [eval concat $$fontSize] \
            [eval concat $$bgColor] \
            [eval concat $$fgColor] \
            [eval concat $$lblColor] \
            [eval concat $$onClickToggle]]
}


proc ::dialog_iemgui::cancel {mytoplevel} {
    pdsend "$mytoplevel cancel"
}

proc ::dialog_iemgui::ok {mytoplevel} {
    ::dialog_iemgui::apply $mytoplevel
    ::dialog_iemgui::cancel $mytoplevel
}

proc ::dialog_iemgui::createSNBWidgets {width height min max logHeight initState linLogState onClickState} {
    ttk::labelframe $::w.windowFrame.sizeAndBehavior -text " Size/Behavior " \
                                                     -padding "5 2 0 2" 
    set ::snb $::w.windowFrame.sizeAndBehavior
    # todo pass in more variables, but with better names
    switch $::iemgui_type {
        {VU Meter} {
            ttk::label $::snb.widthLabel -text "Width:" 
            ttk::entry $::snb.widthEntry -width 5 -textvariable $width 
            ttk::label $::snb.heightLabel -text "Height:" 
            ttk::entry $::snb.heightEntry -width 5 -textvariable $height 
            ttk::label $::snb.showScaleLabel -text "Show Scale" 
            ttk::checkbutton $::snb.showScale -variable ::showScale  \
                -command "::dialog_iemgui::setVUMeterScale $::w"
            set ::showScale $linLogState
        } 
        "Canvas" {
            # (Bang Mappings) SelectionSize->width width->min height->max
            ttk::label $::snb.widthLabel -text "Width:" 
            ttk::entry $::snb.widthEntry -width 5 -textvariable $min 
            ttk::label $::snb.heightLabel -text "Height:" 
            ttk::entry $::snb.heightEntry -width 5 -textvariable $max 
            ttk::label $::snb.sizeLabel -text "Selection Size:" 
            ttk::entry $::snb.sizeEntry -width 5 -textvariable $width 
        }
        "Bang" {
            # (Bang Mappings) Size->Width interrupt->min hold->max
            ttk::label $::snb.sizeLabel -text "Size:" 
            ttk::entry $::snb.sizeEntry -width 5 -textvariable $width 
            ttk::label $::snb.interruptLabel -text "Interrupt:" 
            ttk::entry $::snb.interruptEntry -width 5 -textvariable $min 
            ttk::label $::snb.holdLabel -text "Hold:" 
            ttk::entry $::snb.holdEntry -width 5 -textvariable $max 
        }
        "Toggle" {
            # (Toggle mappings) Size->Width OnValue->Min
            ttk::label $::snb.sizeLabel -text "Size:" 
            ttk::entry $::snb.sizeEntry -width 5 -textvariable $width 
            ttk::label $::snb.onValueLabel -text "On Value:" 
            ttk::entry $::snb.onValueEntry -width 5 -textvariable $min 
            ttk::label $::snb.initLabel -text "Initialize" 
            ttk::checkbutton $::snb.init -command "::dialog_iemgui::setInitState $::w" \
                                         -variable ::tglInit 
            set ::tglInit $initState
        }
        "Radio" {
            # (Radio mappings) Size->Width numCells->logHeight
            ttk::label $::snb.sizeLabel -text "Size:" 
            ttk::entry $::snb.sizeEntry -width 5 -textvariable $width 
            ttk::label $::snb.numCellsLabel -text "Num Cells:" 
            ttk::entry $::snb.numCellsEntry -width 5 -textvariable $logHeight 
            ttk::label $::snb.initLabel -text "Initialize" 
            ttk::checkbutton $::snb.init -command "::dialog_iemgui::setInitState $::w" \
                                         -variable ::radioInit 
            set ::radioInit $initState
        }
        "Slider" {
            ttk::frame $::snb.sizeAndLimits 
            ttk::label $::snb.sizeAndLimits.widthLabel -text "Width:" 
            ttk::entry $::snb.sizeAndLimits.widthEntry -width 5 -textvariable $width 
            ttk::label $::snb.sizeAndLimits.heightLabel -text "Height:" 
            ttk::entry $::snb.sizeAndLimits.heightEntry -width 5 -textvariable $height 
            ttk::label $::snb.sizeAndLimits.minLabel -text "Minimum:" 
            ttk::entry $::snb.sizeAndLimits.minEntry -width 5 -textvariable $min 
            ttk::label $::snb.sizeAndLimits.maxLabel -text "Maximum:" 
            ttk::entry $::snb.sizeAndLimits.maxEntry -width 5 -textvariable $max 
            ttk::frame $::snb.checkButtons  -padding 2
            ttk::checkbutton $::snb.checkButtons.init -text "Initalize" -command "::dialog_iemgui::setInitState $::w" \
                                                      -variable ::sliderInit 
            set ::sliderInit $initState
            ttk::checkbutton $::snb.checkButtons.scaleLog -text "Logarithmic" -command "::dialog_iemgui::linLog $::w" \
                                                          -variable ::sliderLinLogState  
            set ::sliderLinLogState $linLogState
            ttk::checkbutton $::snb.checkButtons.onClick -textvariable ::onClickText -command "::dialog_iemgui::onClick $::w" \
                                                         -variable ::onClickState 
            set ::onClickState $onClickState;# todo rename the function argument
            if {$onClickState == 1} {
                set ::onClickText "Steady"
            } else {
                set ::onClickText "Jump"
            }
        }
        "Number" {
            ttk::label $::snb.widthLabel -text "Width:" 
            ttk::entry $::snb.widthEntry -width 5 -textvariable $width 
            ttk::label $::snb.heightLabel -text "Height:"  
            ttk::entry $::snb.heightEntry -width 5 -textvariable $height 
            ttk::label $::snb.minLabel -text "Minimum:" 
            ttk::entry $::snb.minEntry -width 5 -textvariable $min 
            ttk::label $::snb.maxLabel -text "Maximum:" 
            ttk::entry $::snb.maxEntry -width 5 -textvariable $max 
            ttk::label $::snb.logLabel -text "Log Height:" 
            ttk::entry $::snb.logEntry -width 5 -textvariable $logHeight 
            ttk::separator $::snb.separator 
            ttk::label $::snb.initLabel -text "Initialize" 
            ttk::checkbutton $::snb.init -command "::dialog_iemgui::setInitState $::w" \
                                         -variable ::nbxInit 
            set ::nbxInit $initState
            ttk::label $::snb.scaleLogLabel -text "Logarithmic" 
            ttk::checkbutton $::snb.scaleLog -command "::dialog_iemgui::linLog $::w" \
                                             -variable ::nbxLinLogState 
            set ::nbxLinLogState $linLogState 
        }
    }
}
# receive then send, because vu meter only has receive
proc ::dialog_iemgui::createSndRcvWidgets {rcvSymbol sndSymbol} {
    ttk::labelframe $::w.windowFrame.sndRcv -text " Messaging "  \
                                            -padding "2 2 0 0"
    if { $::iemgui_type != "VU Meter" } {
        ttk::label $::w.windowFrame.sndRcv.sendLabel -text "Send symbol:" 
        ttk::entry $::w.windowFrame.sndRcv.sendEntry -textvariable $sndSymbol -width 16 
    }
    ttk::label $::w.windowFrame.sndRcv.rcvLabel -text "Receive symbol:" 
    ttk::entry $::w.windowFrame.sndRcv.rcvEntry -textvariable $rcvSymbol -width 16 
}
proc ::dialog_iemgui::createLabelWidgets {current_font name xPos yPos fontSize} {
    ttk::labelframe $::w.windowFrame.label -text " Label " -padding 2 
    ttk::label $::w.windowFrame.label.nameLabel -text "Label:" 
    ttk::entry $::w.windowFrame.label.nameEntry -textvariable $name -width 10 \
                                    -font [list $current_font 14 $::font_weight] 
    ttk::label $::w.windowFrame.label.xPosLabel -text "x:" 
    ttk::entry $::w.windowFrame.label.xPosEntry -textvariable $xPos -width 3 
    ttk::label $::w.windowFrame.label.yPosLabel -text "y:" 
    ttk::entry $::w.windowFrame.label.yPosEntry -textvariable $yPos -width 3 
    ttk::label $::w.windowFrame.label.fontLabel -text "Font:" 
    # todo can fontType replace $current_font? (or the opposite)
    ttk::combobox $::w.windowFrame.label.fonts -values [list $::font_family "Helvetica" "Times"] \
                                   -state readonly -textvariable ::fontType -width 8 
    set ::fontType $current_font
    bind  $::w.windowFrame.label.fonts <<ComboboxSelected>> { 
        ::dialog_iemgui::setFont $::w
        $::w.windowFrame.label.fonts selection clear ;# clear selection once font is chosen
    }
    ttk::label $::w.windowFrame.label.fontSizeLabel -text "Font Size:"  -padding "5 0 0 0"
    ttk::label $::w.windowFrame.label.pad3 -text "  " 
    ttk::entry $::w.windowFrame.label.fontSizeEntry -textvariable $fontSize -width 3 
}
proc ::dialog_iemgui::createColorWidgets {} {
    ttk::labelframe $::w.windowFrame.colors -padding 2 -text " Colors " 
    ttk::button $::w.windowFrame.colors.bg -text "Background" -command "::dialog_iemgui::chooseBgColor $::w" -width 9 
    ttk::frame  $::w.windowFrame.colors.bgSample -width 60 -height 25 -style bg.TFrame
    if {$::iemgui_type != "VU Meter" && $::iemgui_type != "Canvas"} {
        ttk::button $::w.windowFrame.colors.fg -text "Foreground" -command "::dialog_iemgui::chooseFgColor $::w" -width 9 
        ttk::frame  $::w.windowFrame.colors.fgSample -width 60 -height 25 -style fg.TFrame
    }
    ttk::button $::w.windowFrame.colors.label -text "Label" -command "::dialog_iemgui::chooseLblColor $::w" -width 4 
    ttk::frame  $::w.windowFrame.colors.lblSample -width 60 -height 25 -style lbl.TFrame
}
proc ::dialog_iemgui::createButtonWidgets {} {
    ttk::frame $::w.windowFrame.buttons -padding "0 6 0 0" 
    # ttk::frame $::w.windowFrame.buttons.pad -width 6
    ttk::button $::w.windowFrame.buttons.cancel -text "Cancel" \
                                                -command "::dialog_iemgui::cancel $::w" 
    ttk::button $::w.windowFrame.buttons.apply  -text "Apply" \
                                                -command "::dialog_iemgui::apply $::w" 
    ttk::button $::w.windowFrame.buttons.ok     -text "OK" \
                                                -command "::dialog_iemgui::ok $::w" -default active 
}

proc ::dialog_iemgui::gridSizeAndBehavior {} {
    grid $::snb -column 0 -row 0 -sticky nwes -pady 1
    switch $::iemgui_type {
        {VU Meter} {
            grid $::snb.widthLabel      -column 0 -row 0 -sticky w
            grid $::snb.widthEntry      -column 1 -row 0
            grid $::snb.heightLabel     -column 0 -row 1 -sticky w -padx 1
            grid $::snb.heightEntry     -column 1 -row 1 -pady 4
            grid $::snb.showScaleLabel  -column 0 -row 2 -sticky w
            grid $::snb.showScale       -column 1 -row 2 -sticky w
        }
        "Canvas" {
            grid $::snb.sizeLabel   -column 0 -row 0 -sticky w
            grid $::snb.sizeEntry   -column 1 -row 0 
            grid $::snb.widthLabel  -column 0 -row 1 -sticky w
            grid $::snb.widthEntry  -column 1 -row 1 -pady 2
            grid $::snb.heightLabel -column 2 -row 1 -sticky w
            grid $::snb.heightEntry -column 3 -row 1
        }
        "Bang" {
            grid $::snb.sizeLabel      -column 0 -row 0 -sticky w
            grid $::snb.sizeEntry      -column 1 -row 0 -sticky w
            grid $::snb.interruptLabel -column 0 -row 1 -sticky w
            grid $::snb.interruptEntry -column 1 -row 1 -sticky w -pady 2
            grid $::snb.holdLabel      -column 2 -row 1 -sticky w 
            grid $::snb.holdEntry      -column 3 -row 1 -sticky w
        }
        "Toggle" {
            grid $::snb.sizeLabel     -column 0 -row 0 -sticky w
            grid $::snb.sizeEntry     -column 1 -row 0
            grid $::snb.onValueLabel  -column 0 -row 1 -sticky w -padx 1
            grid $::snb.onValueEntry  -column 1 -row 1 -pady 4
            grid $::snb.initLabel     -column 0 -row 2 -sticky w
            grid $::snb.init          -column 1 -row 2 -sticky w
        }
        "Radio" {
            grid $::snb.sizeLabel     -column 0 -row 0 -sticky w
            grid $::snb.sizeEntry     -column 1 -row 0
            grid $::snb.numCellsLabel -column 0 -row 1 -sticky w
            grid $::snb.numCellsEntry -column 1 -row 1 -pady 4
            grid $::snb.initLabel     -column 0 -row 2 -sticky w
            grid $::snb.init          -column 1 -row 2 -sticky w
        }
        "Slider" {
            grid $::snb.sizeAndLimits             -column 0 -row 0 -sticky nwes
            grid $::snb.sizeAndLimits.widthLabel  -column 0 -row 0 -sticky w
            grid $::snb.sizeAndLimits.widthEntry  -column 1 -row 0
            grid $::snb.sizeAndLimits.heightLabel -column 2 -row 0 -sticky w
            grid $::snb.sizeAndLimits.heightEntry -column 3 -row 0
            grid $::snb.sizeAndLimits.minLabel    -column 0 -row 1 -pady 4
            grid $::snb.sizeAndLimits.minEntry    -column 1 -row 1
            grid $::snb.sizeAndLimits.maxLabel    -column 2 -row 1
            grid $::snb.sizeAndLimits.maxEntry    -column 3 -row 1
            grid $::snb.checkButtons              -column 0 -row 2 -sticky we
            grid $::snb.checkButtons.init         -column 1 -row 2 -sticky w
            grid $::snb.checkButtons.scaleLog     -column 2 -row 2 -sticky w
            grid $::snb.checkButtons.onClick      -column 3 -row 2 -sticky w
        }
        "Number" {
            grid $::snb.widthLabel    -column 0 -row 0 -sticky w
            grid $::snb.widthEntry    -column 1 -row 0
            grid $::snb.heightLabel   -column 2 -row 0 -sticky w
            grid $::snb.heightEntry   -column 3 -row 0
            grid $::snb.minLabel      -column 0 -row 1 -sticky w
            grid $::snb.minEntry      -column 1 -row 1 -pady 2
            grid $::snb.maxLabel      -column 2 -row 1 -sticky w
            grid $::snb.maxEntry      -column 3 -row 1
            grid $::snb.separator     -column 0 -row 2 -columnspan 4 -sticky we -pady 2
            grid $::snb.logLabel      -column 0 -row 3 -sticky w
            grid $::snb.logEntry      -column 1 -row 3 -pady 2
            grid $::snb.initLabel     -column 0 -row 4 -sticky w -pady 2
            grid $::snb.init          -column 1 -row 4 -sticky w
            grid $::snb.scaleLogLabel -column 2 -row 4 -sticky w
            grid $::snb.scaleLog      -column 3 -row 4 -sticky w
        }
    }
}
proc ::dialog_iemgui::gridSndRcv {} {
    grid $::w.windowFrame.sndRcv  -column 0 -row 2 -sticky nwes -pady 1
    if { $::iemgui_type != "VU Meter" } {
        grid $::w.windowFrame.sndRcv.sendLabel -column 0 -row 0 -sticky w
        grid $::w.windowFrame.sndRcv.sendEntry -column 1 -row 0
    }
    grid $::w.windowFrame.sndRcv.rcvLabel -column 0 -row 1 -sticky w
    grid $::w.windowFrame.sndRcv.rcvEntry -column 1 -row 1 -pady 4
}
proc ::dialog_iemgui::gridLabel {} {
    grid $::w.windowFrame.label -column 0 -row 3 -sticky nwes -pady 1
    grid $::w.windowFrame.label.nameLabel     -column 0 -row 0 -sticky w
    grid $::w.windowFrame.label.nameEntry     -column 1 -row 0 
    grid $::w.windowFrame.label.xPosLabel     -column 2 -row 0
    grid $::w.windowFrame.label.xPosEntry     -column 3 -row 0 -ipadx 2
    grid $::w.windowFrame.label.yPosLabel     -column 4 -row 0
    grid $::w.windowFrame.label.yPosEntry     -column 5 -row 0
    grid $::w.windowFrame.label.fontLabel     -column 0 -row 1 -sticky w
    grid $::w.windowFrame.label.fonts         -column 1 -row 1 -pady 5
    grid $::w.windowFrame.label.fontSizeLabel -column 2 -row 1 -columnspan 2
    grid $::w.windowFrame.label.pad3          -column 4 -row 1
    grid $::w.windowFrame.label.fontSizeEntry -column 5 -row 1 
}
proc ::dialog_iemgui::gridColors {} {
    grid $::w.windowFrame.colors -column 0 -row 4 -sticky nwes -pady 1
    if { $::iemgui_type == "Canvas" || $::iemgui_type == "VU Meter" } {
        grid $::w.windowFrame.colors.bg -column 0 -row 0 -padx 5
        grid $::w.windowFrame.colors.bgSample -column 1 -row 0 -padx 10
        grid $::w.windowFrame.colors.label -column 0 -row 1 -padx 5
        grid $::w.windowFrame.colors.lblSample -column 1 -row 1 -padx 10
    } else {
        grid $::w.windowFrame.colors.bg        -column 0 -row 0 -padx 5
        grid $::w.windowFrame.colors.bgSample  -column 1 -row 0 -padx 10
        grid $::w.windowFrame.colors.fg        -column 0 -row 1 -padx 5
        grid $::w.windowFrame.colors.fgSample  -column 1 -row 1 -padx 10
        grid $::w.windowFrame.colors.label     -column 0 -row 2 -padx 5
        grid $::w.windowFrame.colors.lblSample -column 1 -row 2 -padx 10
    }
}
proc ::dialog_iemgui::gridButtons {} {
    grid $::w.windowFrame.buttons        -column 0 -row 5 -sticky ns
    grid $::w.windowFrame.buttons.ok     -column 0 -row 0
    grid $::w.windowFrame.buttons.apply  -column 1 -row 0 -padx 1
    grid $::w.windowFrame.buttons.cancel -column 2 -row 0
}
proc ::dialog_iemgui::gridIemGui {} {
    grid $::w.windowFrame -column 0 -row 0 -sticky nwes 
    gridSizeAndBehavior 
    gridSndRcv  
    gridLabel   
    gridColors 
    gridButtons
}

proc ::dialog_iemgui::pdtk_iemgui_dialog {mytoplevel iemgui_type UNUSED width_ minWidth_ UNUSED \
                                          height_ minHeight_ UNUSED UNUSED minRange_ UNUSED maxRange_ \
                                          UNUSED rng_sched linLogState_ UNUSED UNUSED initState_ \
                                          onClickToggle_ UNUSED logHeight_ sndSymbol rcvSymbol guiName_ \
                                          fontXPos_ fontYPos_ fontType_ fontSize_ \
                                          bgColor_ fgColor_ lblColor_} {
# Get iemgui_type
    array set iemguiTypes {
        "|bang|"   "Bang"
        "|tgl|"    "Toggle"
        "|nbx|"    "Number"
        "|vsl|"    "Slider"
        "|hsl|"    "Slider"
        "|vradio|" "Radio"
        "|hradio|" "Radio"
        "|vu|"     "VU Meter"
        "|cnv|"    "Canvas"
    }
    set ::iemgui_type $iemguiTypes($iemgui_type)

# Init Init Init
    set vid [string trimleft $mytoplevel .]

    set width [concat iemgui_wdt_$vid]
    global $width
    set $width $width_

    set minWidth [concat iemgui_min_wdt_$vid]
    global $minWidth
    set $minWidth $minWidth_

    set height [concat iemgui_hgt_$vid]
    global $height
    set $height $height_

    set minHeight [concat iemgui_min_hgt_$vid]
    global $minHeight
    set $minHeight $minHeight_

    set minRange [concat iemgui_min_rng_$vid]
    global $minRange
    set $minRange $minRange_

    set maxRange [concat iemgui_max_rng_$vid]
    global $maxRange
    set $maxRange $maxRange_

    # todo figure out what this variable does
    set var_iemgui_rng_sch [concat iemgui_rng_sch_$vid]
    global $var_iemgui_rng_sch
    set $var_iemgui_rng_sch $rng_sched

    set linLogState [concat iemgui_lin0_log1_$vid]
    global $linLogState
    set $linLogState $linLogState_

    set initState [concat iemgui_loadbang_$vid]
    global $initState
    set $initState $initState_

    set logHeight [concat iemgui_num_$vid]
    global $logHeight
    set $logHeight $logHeight_

    set onClickToggle [concat iemgui_steady_$vid]
    global $onClickToggle
    set $onClickToggle $onClickToggle_

    set fontXPos [concat iemgui_gn_dx_$vid]
    global $fontXPos
    set $fontXPos $fontXPos_

    set fontYPos [concat iemgui_gn_dy_$vid]
    global $fontYPos
    set $fontYPos $fontYPos_

    set fontType [concat iemgui_gn_f_$vid]
    global $fontType
    set $fontType $fontType_

    set fontSize [concat iemgui_gn_fs_$vid]
    global $fontSize
    set $fontSize $fontSize_

    set bgColor [concat iemgui_bcol_$vid]
    global $bgColor
    set $bgColor $bgColor_

    set fgColor [concat iemgui_fcol_$vid]
    global $fgColor
    set $fgColor $fgColor_

    set lblColor [concat iemgui_lcol_$vid]
    global $lblColor
    set $lblColor $lblColor_

    set sndSym [concat iemgui_snd_$vid]
    global $sndSym
    set rcvSym [concat iemgui_rcv_$vid]
    global $rcvSym
    set guiName [concat iemgui_gui_nam_$vid]
    global $guiName

    if {$sndSymbol == "empty"} {
        set $sndSym [format ""]
    } else {
        set $sndSym [format "%s" $sndSymbol]
    }
    if {$rcvSymbol == "empty"} {
        set $rcvSym [format ""]
    } else {
        set $rcvSym [format "%s" $rcvSymbol]
    }
    if {$guiName_ == "empty"} {
        set $guiName [format ""]
    } else {
        set $guiName [format "%s" $guiName_]
    }

    if {[string index [eval concat $$sndSym] 0] == "#"} {
        set $sndSym [string replace [eval concat $$sndSym] 0 0 $] 
    }
    if {[string index [eval concat $$rcvSym] 0] == "#"} {
        set $rcvSym [string replace [eval concat $$rcvSym] 0 0 $] 
    }
    if {[string index [eval concat $$guiName] 0] == "#"} {
        set $guiName [string replace [eval concat $$guiName] 0 0 $] 
    }

# Top Level Stuff
    toplevel $mytoplevel
    wm title $mytoplevel [format [_ "%s Properties"] $::iemgui_type]
    wm group $mytoplevel .
    wm resizable $mytoplevel 0 0
    wm transient $mytoplevel $::focused_window
    $mytoplevel configure -menu $::dialog_menubar
    $mytoplevel configure -padx 0 -pady 0
    ::pd_bindings::dialog_bindings $mytoplevel "iemgui"
    set ::w $mytoplevel

# Theme and Style
    ttk::style configure bg.TFrame -background [eval concat $$bgColor]  -relief groove
    ttk::style configure fg.TFrame -background [eval concat $$fgColor]  -relief groove
    ttk::style configure lbl.TFrame -background [eval concat $$lblColor] -relief groove

# Create and grid widgets
    ttk::frame $::w.windowFrame -padding "5 3" 
    ::dialog_iemgui::createSNBWidgets $width $height $minRange $maxRange \
                                      $logHeight $initState_ $linLogState_ $onClickToggle_
    ::dialog_iemgui::createSndRcvWidgets $rcvSym $sndSym

    # get the current font name from the int given from C-space (fontType)
    # todo refactor this
    set current_font $::font_family
    if {[eval concat $$fontType] == 1} { 
        set current_font "Helvetica" 
    }
    if {[eval concat $$fontType] == 2} { 
        set current_font "Times" 
    }

    ::dialog_iemgui::createLabelWidgets $current_font $guiName $fontXPos $fontYPos $fontSize
    ::dialog_iemgui::createColorWidgets 
    ::dialog_iemgui::createButtonWidgets
    ::dialog_iemgui::gridIemGui 

# live widget updates on OSX
    if {$::windowingsystem eq "aqua"} {
        # call apply on Return in entry boxes that are in focus & rebind Return to ok button
        switch $::iemgui_type {
            {VU Meter} {
                bind $::snb.widthEntry  <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.heightEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                $::snb.widthEntry  config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.heightEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
            }
            "Canvas" {
                bind $::snb.widthEntry  <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.heightEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.sizeEntry   <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                $::snb.widthEntry  config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.heightEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.sizeEntry   config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
            }
            "Bang" {
                bind $::snb.sizeEntry      <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.interruptEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.holdEntry      <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                $::snb.sizeEntry      config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.interruptEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.holdEntry      config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
            }
            "Toggle" {
                bind $::snb.sizeEntry    <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.onValueEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                $::snb.sizeEntry    config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.onValueEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
            }
            "Radio" {
                bind $::snb.sizeEntry     <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.numCellsEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                $::snb.sizeEntry     config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.numCellsEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
            }
            "Slider" {
                bind $::snb.sizeAndLimits.widthEntry  <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.sizeAndLimits.heightEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.sizeAndLimits.minEntry    <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.sizeAndLimits.maxEntry    <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                $::snb.sizeAndLimits.widthEntry  config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.sizeAndLimits.heightEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.sizeAndLimits.minEntry    config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.sizeAndLimits.maxEntry    config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
            }
            "Number" {
                bind $::snb.widthEntry  <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.heightEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.minEntry    <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.maxEntry    <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                bind $::snb.logEntry    <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
                $::snb.widthEntry  config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.heightEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.minEntry    config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.maxEntry    config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
                $::snb.logEntry    config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
            }
        }

        bind $::w.windowFrame.label.nameEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
        if {$::iemgui_type != "VU Meter"} {
            bind $::w.windowFrame.sndRcv.sendEntry  <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
            $::w.windowFrame.sndRcv.sendEntry    config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
        }
        bind $::w.windowFrame.sndRcv.rcvEntry     <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
        bind $::w.windowFrame.label.xPosEntry     <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
        bind $::w.windowFrame.label.yPosEntry     <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"
        bind $::w.windowFrame.label.fontSizeEntry <KeyPress-Return> "::dialog_iemgui::apply_and_rebind_return $::w"

        # unbind Return from ok button when an entry takes focus
        $::w.windowFrame.label.nameEntry     config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
        $::w.windowFrame.sndRcv.rcvEntry     config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
        $::w.windowFrame.label.xPosEntry     config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
        $::w.windowFrame.label.yPosEntry     config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"
        $::w.windowFrame.label.fontSizeEntry config -validate focusin -validatecommand "::dialog_iemgui::unbind_return $::w"

        # remove cancel button from focus list since it's not activated on Return
        $::w.windowFrame.buttons.cancel configure -takefocus 0

        # show active focus on the ok button as it *is* activated on Return
        $::w.windowFrame.buttons.ok configure -default normal
        # bind $::w.windowFrame.buttons.ok <FocusIn> "$::w.windowFrame.buttons.ok config -default active"
        # bind $::w.windowFrame.buttons.ok <FocusOut> "$::w.windowFrame.buttons.ok config -default normal"

        # since we show the active focus, disable the highlight outline
        # $::w.windowFrame.buttons.ok configure -highlightthickness 0
        # $::w.windowFrame.buttons.cancel configure -highlightthickness 0
    }

    position_over_window $mytoplevel $::focused_window
}

# for live widget updates on OSX
proc ::dialog_iemgui::apply_and_rebind_return {mytoplevel} {
    ::dialog_iemgui::apply $mytoplevel
    bind $mytoplevel <KeyPress-Return> "::dialog_iemgui::ok $mytoplevel"
    focus $mytoplevel.windowFrame.buttons.ok
    return 0
}

proc ::dialog_iemgui::unbind_return {mytoplevel} {
    bind $mytoplevel <KeyPress-Return> break
    return 1
}
