; asmsyntax=ca65

LS_CURSOR_COLOR_START = $21
LS_CURSOR_COLOR_END = $2D
LS_CURSOR_ANIM_FRAMES = 3
ls_cursorColorBuff = PaletteBufferSprites + 15

CURSOR_TILE = $26

.pushseg

.segment "ZEROPAGE" : zeropage

; Horizontal scroll for the map
menu_ScrollValue:   .res 1
menu_DrawnSprites:  .res 1
menu_LoadedSprites: .res 1
LEVELSELECT_SPRITE_OFFSET = 5

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
ls_cursorAnim: .res 1   ; Cursor color animation thing

ls_AttrUpdate: .res 1
ls_AttrUpdate_Clr: .res 1

ls_TmpTracePointer: .res 2

ls_PrevTraceAddr: .res 2
ls_PrevTraceData: .res 1

.segment "MAINRAM"
title_MenuLength: .res 1
title_MenuItems: .res 10

; Level that was just completed.  $FF if from title screen.
; Used to determine position in level select.
menu_PrevLevel: .res 1

; Relative to nametable, not current scroll.
ls_SpriteX: .res 32
ls_SpriteY: .res 32

; Bit 7 - Flip Vertically
; Bit 6 - Flip Horizontally
; Bit 5 - Priority
; Bit 4 - unused
; Bit 3 - X coord 9th bit
; Bit 2 - unused
; Bits 0,1 - Palette ID
ls_SpriteFlags: .res 32

; Tile IDs
ls_SpriteTiles: .res 32

; one entry per sprite obj
ls_SpriteFrames: .res 32
ls_SpriteFrameTimer: .res 32

ls_PaletteFrames: .res 16
ls_PaletteFrameTimer: .res 16

ls_PalTmp: .res 4

ls_NumActiveLevels: .res 1  ; number of options available
ls_ActiveLevels: .res 8     ; list of indexes for active level icons
ls_SelectedLevel: .res 1
ls_SelectedLevel_Prev: .res 1

ls_PrevTraceCount: .res 1
ls_PrevTraces: .res 10

.popseg
