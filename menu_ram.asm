; asmsyntax=ca65

.pushseg

.segment "ZPMENU" : zeropage

; Horizontal scroll for the map
menu_ScrollValue:   .res 1
menu_DrawnSprites:  .res 1
menu_LoadedSprites: .res 1
LEVELSELECT_SPRITE_OFFSET = 5

; Pointers to animation update routines for sprites
;menu_AnimationPointers: .res 32

; Pointers to scroll update routines for sprites
;menu_ScrollPointers:    .res 32

tmp_SpriteX: .res 1
tmp_SpriteY: .res 1
tmp_SpriteTile: .res 1
tmp_SpriteFlags: .res 1

tmp_BaseX:  .res 1
tmp_BaseY:  .res 1

ls_SpritesToLoad: .res 1

; Palette data idx for modem sprites
ls_ModemPal: .res 1

; Pointer to the progression data
ls_LevelProg: .res 2
;ls_cursorColor: .res 1
ls_cursorAnim: .res 1

LS_CURSOR_COLOR_START = $21
LS_CURSOR_COLOR_END = $2D
LS_CURSOR_ANIM_FRAMES = 3
ls_cursorColorBuff = PaletteBufferSprites + 15

.segment "RAMMENU"
title_MenuLength: .res 1
title_MenuItems: .res 10

; Level that was just completed.  $FF if from title screen.
menu_PrevLevel: .res 1

; Width and height of the icon
menu_LevelWidth:  .res 16
menu_LevelHeight: .res 16

; Relative to nametable, not current scroll.
ls_SpriteX: .res 16
ls_SpriteY: .res 16

; Bit 7 - Flip Vertically
; Bit 6 - Flip Horizontally
; Bit 5 - Priority
; Bit 4 - unused
; Bit 3 - X coord 9th bit
; Bit 2 - unused
; Bits 0,1 - Palette ID
ls_SpriteFlags: .res 16

; Tile IDs
ls_SpriteTiles: .res 16

; one entry per sprite obj
ls_SpriteFrames: .res 16
ls_SpriteFrameTimer: .res 16

ls_PaletteFrames: .res 8
ls_PaletteFrameTimer: .res 8

ls_PalTmp: .res 4

ls_NumActiveLevels: .res 1  ; number of options available
ls_ActiveLevels: .res 8     ; list of indexes for active levels
ls_SelectedLevel: .res 1

; X/Y of each meta-sprite (X is 9bit number)
; Sprite flags
; Animation interval
; x/y offsets of sub-sprites
; Start sprite ID
.popseg

