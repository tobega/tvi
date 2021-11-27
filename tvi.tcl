#!/home/tstgm/local/bin/wish

#specialare eftersom vi vill att Delete skall funka som BackSpace
bind Text <Key-Delete> {
    if {![string compare [lindex [%W tag nextrange sel 1.0 end] end] [%W index insert]]} {
        %W delete sel.first sel.last
    } elseif {[%W compare insert != 1.0]} {
        %W delete insert-1c
        %W see insert
    }
}
bind Entry <Key-Delete> { tkEntryBackspace %W }

#backspace och Paste modifieras för bättre funktion
bind Text <Key-BackSpace> {
    if {![string compare [lindex [%W tag nextrange sel 1.0 end] end] [%W index insert]]} {
        %W delete sel.first sel.last
    } elseif {[%W compare insert != 1.0]} {
        %W delete insert-1c
        %W see insert
    }
}
bind Text <<Paste>> {
    if {![string compare [lindex [%W tag nextrange sel 1.0 end] end] [%W index insert]]} {
        %W delete sel.first sel.last
    }
    tk_textPaste %W
}

# do not want this function
bind all <Key-Tab> {}

# Menyerna
menu .mb -type menubar
. configure -menu .mb
# Filemenyn
.mb add cascade -label File -menu .mb.f
  menu .mb.f -type normal
  .mb.f add command -label Save -accelerator "Ctrl-s" -command spar_arbetsfil
  .mb.f add command -label "Save As..." -command sparasom
  .mb.f add separator
  .mb.f add command -label "Quit and Save" -command "spar_arbetsfil; exit" -accelerator "Ctrl-q"
  .mb.f add separator
  .mb.f add command -label "Open new window" -command "exec $argv0 &"
  .mb.f add separator
  .mb.f add command -label "Open..." -command oppna
  .mb.f add command -label "Revert" -command las_arbetsfil
  .mb.f add command -label "Abort" -command exit
bind all <Control-Key-s> spar_arbetsfil
bind all <Control-Key-q> "spar_arbetsfil; exit"

# Editmenyn
.mb add cascade -label Edit -menu .mb.e
  menu .mb.e -type normal
  .mb.e add command -label Cut -accelerator "Ctrl-x" -command "event generate .t <<Cut>>"
  .mb.e add command -label Copy -accelerator "Ctrl-c" -command "event generate .t <<Copy>>"
  .mb.e add command -label Paste -accelerator "Ctrl-v" -command "event generate .t <<Paste>>"
bind Text <Control-Key-x> {event generate %W <<Cut>>}
bind Text <Control-Key-c> {event generate %W <<Copy>>}
bind Text <Control-Key-v> {event generate %W <<Paste>>}

# Findmenyn
.mb add cascade -label Search -menu .mb.s
  menu .mb.s -type normal
  .mb.s add command -label "Find..." -command "finn_dialog" -accelerator "Ctrl-g"
  .mb.s add command -label "Find next" -accelerator "Ctrl-f" -command finn_igen
  .mb.s add command -label "Find previous" -accelerator "Ctrl-r" -command "finn_igen bak"
  .mb.s add separator
  .mb.s add command -label "Find selected ->" -accelerator "Ctrl-F" -command finn_selected
  .mb.s add command -label "Find selected <-" -accelerator "Ctrl-R" -command "finn_selected bak"
  .mb.s add separator
  .mb.s add command -label "Change Text..." -command "bytut_dialog"
bind Text <Control-Key-g> finn_dialog
bind Text <Control-Key-f> finn_igen
bind Text <Control-Key-r> "finn_igen bak"
bind Text <Control-Key-F> finn_selected
bind Text <Control-Key-R> "finn_selected bak"

# Helpmenyn
.mb add cascade -label Help -menu .mb.help
  menu .mb.help -type normal
  .mb.help add command -label "Help..." -command "help tvi"
  .mb.help add command -label "Tour of help..." -command "help_tour"

#bonusbindningar
bind Entry <Control-Key-x> {event generate %W <<Cut>>}
bind Entry <Control-Key-c> {event generate %W <<Copy>>}
bind Entry <Control-Key-v> {event generate %W <<Paste>>}

# Innehållet
frame .s
pack .s -side bottom -fill x
entry .s.el -width 6 -textvariable markrad -justify right
pack .s.el -side right
label .s.ll -text "Line:"
pack .s.ll -side right
entry .s.s -state disabled -textvariable status -relief flat
pack .s.s -side top -fill x
scrollbar .h -orient horizontal -command ".t xview"
scrollbar .v -orient vertical -command ".t yview"
pack .v -side right -fill y
pack .h -side bottom -fill x
text .t -xscrollcommand ".h set" -yscrollcommand ".v set" -height 40 -width 80 -wrap none -exportselection yes
pack .t
# Sätt focus till textfönstret
focus .t

bind .t <Control-Key-h> {help Text}
bind .t <Control-Key-l> {focus .s.el; .s.el selection range 0 end}

# radbyte och markeringar via Line-entry
bind .s.el <Key-Return> {
  if { [string is integer -strict $markrad] } {
    .t mark set insert $markrad.0
    .t see insert
    focus .t
  } elseif { [lsearch -exact [.t mark names] $markrad] < 0 } {
    bell
  } else {
    .t mark set insert [.t index $markrad]
    .t see insert
    focus .t
  }
}
bind .s.el <Control-Key-h> {help Line}
bind .s.el <Control-Key-m> {
  if { [string is integer -strict $markrad] } {
    bell
  } else {
    .t mark set $markrad [.t index insert]
    focus .t
  }
}

# loggning av texten
bindtags .t {.t Text . all logga}
bind logga <Key> {set markrad [file rootname [.t index insert]]}
bind logga <ButtonRelease> {set markrad [file rootname [.t index insert]]}

#initieringar för finn
set finnord ""
set finntyp "nocase"
set funnen ""
set finnriktning forwards
set utbytesord ""

#initieringar för fil
set filtyper {
{{all files} *}
{{C source files} {.c}}
{{C header files} {.h}}
{{shell scripts} {.sh}}
}
set arbetsfil ""
set arbetsdir ""
wm title . "New file"
if { $argc > 0 } {
  set fil [lindex $argv 0]
    set arbetsfil $fil
    set arbetsdir [file dirname $fil]
    wm title . [file tail $arbetsfil]
  if { $argc > 1 } {
    foreach fil [lrange $argv 1 end] {
      exec $argv0 $fil "&"
    }
  }
}

proc las_arbetsfil {} {
global arbetsfil status
 .t delete 1.0 end
 if { [string length $arbetsfil] != 0 && [file exists $arbetsfil]} {
    set c [open $arbetsfil]
    set allt [read -nonewline $c]
    close $c
    .t insert end "$allt"
  }
  .t mark set insert 1.0
  set status "File read [clock format [clock seconds] -format "%H:%M:%S"]"
}

las_arbetsfil

proc oppna {} {
global arbetsfil arbetsdir filtyper
set fil [tk_getOpenFile -filetypes $filtyper -initialdir $arbetsdir]
if { [string length $fil] != 0 } {
  set arbetsfil $fil
  set arbetsdir [file dirname $fil]
  wm title . [file tail $arbetsfil]
  las_arbetsfil
}
}

proc spar_arbetsfil {} {
global arbetsfil status
if { [string length $arbetsfil] != 0 } {
  set allt [.t get 1.0 end]
  set c [open $arbetsfil w]
  puts -nonewline $c "$allt"
  close $c
  set status "Saved [clock format [clock seconds] -format "%H:%M:%S"]"
} else sparasom
}

proc sparasom {} {
global arbetsfil arbetsdir filtyper
set fil [tk_getSaveFile -filetypes $filtyper -initialfile "[file tail $arbetsfil]" -initialdir $arbetsdir]
if { [string length $fil] != 0 } {
  set arbetsfil $fil
  set arbetsdir [file dirname $fil]
  wm title . [file tail $arbetsfil]
  spar_arbetsfil
}
}

proc bytut_dialog {} {
global bytfran byttill byttyp
set bytfran ""
set byttill ""
set byttyp "exact"
if { [winfo exists .bytut] } "raise .bytut" else {
  toplevel .bytut
  wm title .bytut "Change Text"
  bind .bytut <Key-Return> {bytut}
  bind .bytut <Control-Key-d> {if { [string compare [.t tag nextrange sel 0.0] ""] != 0 } {
    selection clear
}
destroy .bytut}
  bind .bytut <Control-Key-e> {set byttyp exact}
  bind .bytut <Control-Key-n> {set byttyp nocase}
  bind .bytut <Control-Key-h> {help "Change Text"}
  frame .bytut.o
  pack .bytut.o -side top -fill x
  frame .bytut.p
  pack .bytut.p -side top -fill x
  frame .bytut.k
  pack .bytut.k -side top -fill x
  frame .bytut.o.l
  pack .bytut.o.l -side left -fill y
  label .bytut.o.l.f -text "Change:"
  pack .bytut.o.l.f -side top -pady 6 -padx 4
  label .bytut.o.l.t -text "To:"
  pack .bytut.o.l.t -side top -pady 6 -padx 4
  frame .bytut.o.e
  pack .bytut.o.e -side left -fill y
  entry .bytut.o.e.f -textvariable bytfran -width 30 -takefocus 0
  pack .bytut.o.e.f -side top -pady 6 -padx 4
  entry .bytut.o.e.t -textvariable byttill -width 30 -takefocus 0
  pack .bytut.o.e.t -side top -pady 6 -padx 4
  label .bytut.p.m -text Match
  pack .bytut.p.m -side left
  tk_optionMenu .bytut.p.t byttyp exact nocase regexp
  pack .bytut.p.t -side left -pady 6 -padx 4
  button .bytut.k.b -text "Replace" -command bytut -default active -takefocus 0
  pack .bytut.k.b -side left -pady 6 -padx 4
  button .bytut.k.n -text "New task" -command {set bytfran ""; set byttill ""; focus -force .bytut.o.e.f} -takefocus 0
  pack .bytut.k.n -side left -pady 6 -padx 4
  button .bytut.k.c -text "Close" -command {if { [string compare [.t tag nextrange sel 0.0] ""] != 0 } {
      selection clear
    }
    destroy .bytut} -takefocus 0
  pack .bytut.k.c -side right -pady 6 -padx 4
  bind .bytut.o.e.f <Key-Tab> {set byttill ""; focus -force .bytut.o.e.t}
  bind .bytut.o.e.t <Key-Tab> {set bytfran ""; focus -force .bytut.o.e.f}
  focus -force .bytut.o.e.f
}
}

proc bytut {} {
global bytfran byttill byttyp
if { [string compare [.t tag nextrange sel 0.0] ""] == 0 } {
    .t tag add sel 1.0 end-1c
}
set area [selection get]
set map ""
lappend map $bytfran
lappend map $byttill
if { [string compare "$byttyp" "exact"] == 0 } {
  set area [string map "$map" "$area"]
} elseif { [string compare "$byttyp" "nocase"] == 0 } {
  set area [string map -nocase "$map" "$area"]
} elseif { [string compare "$byttyp" "regexp"] == 0 } {
  regsub -all -- "$bytfran" "$area" "$byttill" area
}
set var [.t index sel.first]
.t delete sel.first sel.last
.t mark set index $var
.t insert $var "$area"
.t tag add sel [.t index $var] [.t index insert]
}

proc finn_dialog {} {
global finnord finntyp funnen
if { [winfo exists .finn] } "raise .finn" else {
  set funnen ""
  toplevel .finn
  wm title .finn "Find Text"
  bind .finn <Key-Return> finn
  bind .finn <Control-Key-f> {finn}
  bind .finn <Control-Key-r> {finn bak}
  bind .finn <Control-Key-d> {destroy .finn}
  bind .finn <Control-Key-h> {help "Find dialog"}
  frame .finn.o
  pack .finn.o -side top -fill x
  frame .finn.p
  pack .finn.p -side top -fill x
  frame .finn.k
  pack .finn.k -side top -fill x
  label .finn.o.f -text "Find:"
  pack .finn.o.f -side left
  entry .finn.o.e -textvariable finnord -width 30 -takefocus 0
  pack .finn.o.e -side left -pady 6 -padx 4
  label .finn.p.m -text Match
  pack .finn.p.m -side left
  tk_optionMenu .finn.p.t finntyp exact nocase regexp
  pack .finn.p.t -side left -pady 6 -padx 4
  button .finn.k.f -text "Forwards" -command finn -default active -takefocus 0
  pack .finn.k.f -side left -pady 6 -padx 4
  button .finn.k.b -text "Backwards" -command "finn bak" -takefocus 0
  pack .finn.k.b -side left -pady 6 -padx 4
  button .finn.k.c -text "Close" -command {destroy .finn} -takefocus 0
  pack .finn.k.c -side right -pady 6 -padx 4
  focus -force .finn.o.e
  .finn.o.e selection range 0 end
  .finn.o.e icursor end
}
}

proc finn { {riktning fram} } {
global finnord finntyp funnen
  if { [string compare $funnen ""] == 0 } { set funnen [.t index insert] }
  if { [string compare $riktning bak] } {
    set funnen [.t search -$finntyp -count finnlen "$finnord" "$funnen +1 chars"]
  } else {
    set funnen [.t search -backwards -$finntyp -count finnlen "$finnord" "$funnen"]
  }
  if { [string compare $funnen ""] } {
    selection clear
    .t tag add sel $funnen "$funnen + $finnlen chars"
    .t mark set insert "$funnen + $finnlen chars"
    .t see insert
  } else {
    tk_messageBox -message "$finnord not found as $finntyp match" -type ok
    finn_dialog
  }
}

proc finn_igen { {riktning fram} } {
global finnord finntyp funnen
  if { [string compare $finnord ""] } {finn $riktning} else {finn_dialog}
}

proc finn_selected { {riktning fram} } {
global finnord finntyp funnen
  set valt [.t tag nextrange sel 1.0 end]
  if {[string compare "$valt" ""]} {
    if {![string compare [lindex $valt end] [.t index insert]]} {
      set finnord [eval .t get $valt]
      set funnen [.t index sel.first]
    }
  } else {
    catch { set valt [selection get] }
    set finnord "$valt"
    set funnen [.t index insert]
  }
  if { [string compare "$finntyp" regexp] && [string compare $finnord ""] } {finn $riktning} else {finn_dialog}
}

set helptexter {
{{tvi} {The following works everywhere:
Ctrl-s to save
Ctrl-q to quit and save

Most windows give help when you press Ctrl-h}}
{{Find dialog} {Return or Ctrl-f to find forwards
Ctrl-r to find backwards
Ctrl-d to close dialog
Right or left Arrow to deselect word}}
{{Text} {select and press Ctrl-F to find selected text forwards
select and press Ctrl-R to find selected text backwards

Ctrl-g to pop up Find dialog
Ctrl-f to find same word again forwards
Ctrl-r to find same word again backwards

Ctrl-l to jump to line}}
{{Line} {Enter line number and press Return to jump to line

Enter name and press Ctrl-m to mark insertion point

Enter name and press Return to jump to mark}}
{{Change Text} {Changes text in selected region or in whole text

Return executes the change
Tab moves to next field and clears it
Ctrl-e for exact match
Ctrl-n for nocase match
Ctrl-d to close dialog}}
}

proc help {what} {
global helptexter
  set i [lsearch -glob $helptexter "\{$what*"]
  if {$i < 0} {
    tk_messageBox -type ok -title "No help" -message "No helptext written for $what"
  } else {
    set a [lindex $helptexter $i]
    tk_messageBox -type ok -title "Help for [lindex $a 0]" -message "[lindex $a 1]"
  }
}

proc help_tour {} {
global helptexter
foreach item $helptexter {
  foreach {what mess} $item {
    tk_messageBox -type ok -title "Help for $what" -message "$mess"
  }
}
tk_messageBox -type ok -title "Help tour end" -message "No more help available"
}
#färdig startstorlek, fixera fönstret och öka .t
if { ! [winfo ismapped .t] } { tkwait visibility .t }
pack propagate . off
.t configure -width 400
.t configure -height 200

