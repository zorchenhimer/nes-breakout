; asmsyntax=ca65

.pushseg

.segment "ZPMENU" : zeropage

; Horizontal scroll for the map
menu_ScrollValue:   .res 1
menu_DrawnSprites:  .res 1
LEVELSELECT_SPRITE_OFFSET = 5

; Pointers to animation update routines for sprites
;menu_AnimationPointers: .res 32

; Pointers to scroll update routines for sprites
;menu_ScrollPointers:    .res 32

.segment "RAMMENU"
title_MenuLength: .res 1
title_MenuItems: .res 10

; Width and height of the icon
menu_LevelWidth:  .res 16
menu_LevelHeight: .res 16

.struct StackAnim

    Frame .byte

    Y0 .byte
    X1 .byte 3
    ;X2 .byte
    ;X3 .byte

.endstruct

anim_StackA: .tag StackAnim
anim_StackB: .tag StackAnim

; Relative to nametable, not current scroll.
ls_SpriteX: .res 16
ls_SpriteY: .res 16

; Bit 7 - X coord 9th bit
; Bit 6 - Priority
; Bit 3 - Flip Vertically
; Bit 2 - Flip Horizontally
; Bits 0,1 - Palette ID
ls_SpriteFlags: .res 16

; Tile IDs
ls_SpriteTiles: .res 16

; X/Y of each meta-sprite (X is 9bit number)
; Sprite flags
; Animation interval
; x/y offsets of sub-sprites
; Start sprite ID
.popseg

