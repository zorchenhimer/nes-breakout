; asmsyntax=ca65

.pushseg

.segment "ZPMENU" : zeropage

; Horizontal scroll for the map
menu_ScrollValue:       .res 1

; Pointers to animation update routines for sprites
menu_AnimationPointers: .res 32

; Pointers to scroll update routines for sprites
menu_ScrollPointers:    .res 32

.segment "RAMMENU"
title_MenuLength: .res 1
title_MenuItems: .res 10

; Width and height of the icon
menu_LevelWidth:  .res 16
menu_LevelHeight: .res 16

; X/Y of each meta-sprite (X is 9bit number)
; Sprite flags
; Animation interval
; x/y offsets of sub-sprites
; Start sprite ID
.popseg

