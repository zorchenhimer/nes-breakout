; asmsyntax=ca65

; All the hand-written data for the level select screen

; Background tile data
; Everything is encoded with RLE Inc.
; Start PPU address, data length, data (tile ID) start
data_LevelIcons:
    ; bricks
    .word $2104
        .byte 3, $00
    .word $2124
        .byte 3, $10

    ; top stack
    .word $208A
        .byte 3, $03
    .word $20AA
        .byte 3, $13
    .word $20CA
        .byte 3, $23

    ; bottom stack
    .word $218A
        .byte 3, $03
    .word $21AA
        .byte 3, $13
    .word $21CA
        .byte 3, $23

    ; modem A
    .word $2052
        .byte 1, $0C
    .word $2071
        .byte 2, $1B

    ; modem B
    .word $2111
        .byte 1, $0C
    .word $2130
        .byte 2, $1B

    ; modem B
    .word $2211
        .byte 1, $0C
    .word $2230
        .byte 2, $1B

    ; top sat
    .word $20B5
        .byte 3, $0D
    .word $20D5
        .byte 3, $1D
    .word $20F6
        .byte 2, $2E

    ; bot sat
    .word $2195
        .byte 3, $0D
    .word $21B5
        .byte 3, $1D
    .word $21D6
        .byte 2, $2E

    ; server 1
    .word $205C
        .byte 2, $06
    .word $207C
        .byte 2, $16

    ; server 2
    .word $20FC
        .byte 2, $06
    .word $211C
        .byte 2, $16

    ; server 3
    .word $219C
        .byte 2, $06
    .word $21BC
        .byte 2, $16

    ; server 4
    .word $221C
        .byte 2, $06
    .word $223C
        .byte 2, $16

    ; Null terminated
    .byte $00

data_PaletteAnim_List:
    .word data_PaletteAnim_Def00

PAL_ANIM_COUNT = (* - data_PaletteAnim_List) / 2

data_PaletteAnim_Def00:
    .byte 5     ; palette index
    .byte 3     ; number of frames
    .byte 6     ; frame rate

    ; frame data
    .byte $20, $20, $00, $00
    .byte $20, $00, $20, $00
    .byte $20, $00, $00, $20
    ;.byte $0F, $0F, $20, $0F

; List of all the sprite objects
; A "sprite object" is a meta-sprite for animation.
data_SpriteObject_List:
    .word data_SpriteObj_Def_Stack
        .byte 112, 35    ; base X/Y
    .word data_SpriteObj_Def_Stack
        .byte 104, 115    ; base X/Y

    .word data_SpriteObj_Def_Modem
        .byte 240, 16
    .word data_SpriteObj_Def_Modem
        .byte 184, 64
    .word data_SpriteObj_Def_Modem
        .byte 168, 112

    ; TODO: 2nd screen
    .word data_SpriteObj_Def_Sat
        .byte 255, 71
    .word data_SpriteObj_Def_Sat
        .byte 232, 127

SPRITE_OBJ_COUNT = (* - data_SpriteObject_List) / 4

; Static "animation" (only palette is animated)
data_SpriteObj_Def_Modem:
    .byte 1         ; animation type
    .byte 1         ; sprite count

    .word data_SpriteObj_02Tiles
    .word data_SpriteObj_02Attr
    .word data_SpriteObj_02X
    .word data_SpriteObj_02Y

data_SpriteObj_02Tiles:
    .byte $0B

data_SpriteObj_02Attr:
    .byte $01

data_SpriteObj_02X:
    .byte $00

data_SpriteObj_02Y:
    .byte $00

data_SpriteObj_Def_Sat:
    .byte 1         ; animation type
    .byte 1         ; sprite count

    .word data_SpriteObj_03Tiles
    .word data_SpriteObj_03Attr
    .word data_SpriteObj_03X
    .word data_SpriteObj_03Y

data_SpriteObj_03Tiles:
    .byte $2D

data_SpriteObj_03Attr:
    .byte $01

data_SpriteObj_03X:
    .byte $00

data_SpriteObj_03Y:
    .byte $00

data_SpriteObj_Def_Stack:
    .byte 0         ; animation type
    .byte 10        ; frame rate
    .byte 3         ; sprite count
    .byte 4         ; frame count

    .word data_SpriteObj_01Tiles
    .word data_SpriteObj_01Attr
    .word data_SpriteObj_01X
    .word data_SpriteObj_01Y
    .word data_SpriteObj_01FrameX
    .word data_SpriteObj_01FrameY

data_SpriteObj_01Tiles:
    .byte $33, $34, $33  ;tile IDs

data_SpriteObj_01Attr:
    .byte 0, 0, $40 ; attr data

; X/Y offsets
data_SpriteObj_01X:
    .byte 0, 8, 16
data_SpriteObj_01Y:
    .byte 0, 0, 0

; Frame data
data_SpriteObj_01FrameX:
    .byte 0, 0, 0, 0
data_SpriteObj_01FrameY:
    .byte 0, 6, 12, 6

; Cursor data for the level select
data_LevelSelect_Cursor:
    ; X, Y, w, h
    ; 1
    .byte 31, 62, 18, 9

    ; 2
    .byte 113, 31, 14, 16
    .byte 105, 111, 14, 16

    ; 3
    .byte 175, 14,  10, 10
    .byte 119, 62,  10, 10
    .byte 119, 110, 10, 10

    ; 4
    .byte 146, 37, 20, 20
    .byte 146, 93, 20, 20

    ; 5
    .byte 202, 13, 12, 12
    .byte 202, 53, 12, 12
    .byte 202, 93, 12, 12
    .byte 202, 125, 12, 12

    ; 6
    .byte 202, 30, 24, 24
    .byte 202, 30, 24, 24
    .byte 202, 30, 24, 24

    ; 7
    .byte 200, 30, 24, 24

; Scroll of screen for each cursor value
data_LevelSelect_CursorScroll:
    ; 1
    .byte 0

    ; 2
    .byte 0
    .byte 0

    ; 3
    .byte 64
    .byte 64
    .byte 48

    ; 4
    .byte 50
    .byte 50

    ; 5
    .byte 50
    .byte 50
    .byte 20
    .byte 50

    ; 6
    .byte 40
    .byte 40
    .byte 40

    ; 7
    .byte 80

; First list of pointers for traces.  Indexed with menu_PrevLevel
from_idx:
    .word from_1

    .word from_2a
    .word from_2b

    .word from_3a
    .word from_3b
    .word from_3c

    .word from_4a
    .word from_4b

    .word from_5a
    .word from_5b
    .word from_5c
    .word from_5d

    .word from_6a
    .word from_6b
    .word from_6c
    ; there is no from_7

; Second list of pointers.  Indexed with ls_SelectedLevel
from_1:
    .word trace_1_2a
    .word trace_1_2b

from_2a:
    .word trace_2a_3a
    .word trace_2a_3b

from_2b:
    .word trace_2b_3b
    .word trace_2b_3c

from_3a:
    .word trace_3a_5a
    .word trace_3a_4a

from_3b:
    .word trace_3b_4a
    .word trace_3b_4b

from_3c:
    .word trace_3c_4b

from_4a:
    .word trace_4a_5b
    .word trace_4a_5c

from_4b:
    .word trace_4b_5b
    .word trace_4b_5c
    .word trace_4b_5d

from_5a:
    .word trace_5a_7

from_5b:
    .word trace_5b_6a
    .word trace_5b_6b

from_5c:
    .word trace_5c_6a
    .word trace_5c_6b

from_5d:
    .word trace_5d_6b
    .word trace_5d_6c

from_6a:
    .word trace_6a_7

from_6b:
    .word trace_6b_7

from_6c:
    .word trace_6c_7

trace_1_2a:
    .word $23C9
    .byte %0101_0000
    .word $23CA
    .byte %0101_0101
    .word $23CB
    .byte %0000_0001
    .word $0000 ; word cuz we need the high byte zero

trace_1_2b:
    .word $23D1
    .byte %0100_0000
    .word $23D9
    .byte %0000_0100
    .word $23DA
    .byte %0101_0101
    .word $23DB
    .byte %0000_0001
    .word $0000

trace_2a_3a:
    .word $23C3
    .byte %0100_0100
    .word $23C4
    .byte %0101_0101
    .word $23C5
    .byte %0101_0000
    .word $23CD
    .byte %0000_0100
    .word $23C6
    .byte %0101_0000
    .word $23CE
    .byte %0000_0101
    .word $23C7
    .byte %0001_0000
    .byte $00

trace_2a_3b:
    .word $23CB
    .byte %0001_0000
    .word $23D3
    .byte %0000_0101
    .word $23D4
    .byte %0000_0101
    .word $23D5
    .byte %0000_0001
    .word $23CC
    .byte %0100_0000
    .word $23CD
    .byte %0101_0000
    .byte $00

trace_2b_3b:
    .word $23DB
    .byte %0000_0100
    .word $23D3
    .byte %0100_0000
    .word $23D4
    .byte %0101_0000
    .word $23D5
    .byte %0101_0000
    .byte $00

trace_2b_3c:
    .word $23DC
    .byte %0101_0000
    .word $23E4
    .byte %0000_0100
    .word $23E5
    .byte %0000_0001
    .byte $00

trace_3a_5a:
trace_3a_4a:
trace_3b_4a:
trace_3b_4b:
trace_3c_4b:
trace_4a_5b:
trace_4a_5c:
trace_4b_5b:
trace_4b_5c:
trace_4b_5d:
trace_5a_7:
trace_5b_6a:
trace_5b_6b:
trace_5c_6a:
trace_5c_6b:
trace_5d_6b:
trace_5d_6c:
trace_6a_7:
trace_6b_7:
trace_6c_7:
    .byte $00

; This table is indexed with menu_PrevLevel
data_Level_Progression_Idx:
    .word :+
    .word :++
    .word :+++
    .word :++++
    .word :+++++
    .word :++++++
    .word :+++++++
    .word :++++++++
    .word :+++++++++
    .word :++++++++++
    .word :+++++++++++
    .word :++++++++++++
    .word :+++++++++++++
    .word :++++++++++++++
    .word :+++++++++++++++
    .word :++++++++++++++++

; Uses menu_PrevLevel to determine which
; levels are available for selection.
data_Level_Progression:
; 1
:   .byte 1, 2, $FF

; 2
:   .byte 3, 4, $FF
:   .byte 4, 5, $FF

; 3
:   .byte 8, 6, $FF
:   .byte 6, 7, $FF
:   .byte 7, $FF

; 4
:   .byte 9, 10, $FF
:   .byte 9, 10, 11, $FF

; 5
:   .byte 15, $FF
:   .byte 12, 13, $FF
:   .byte 12, 13, $FF
:   .byte 13, 14, $FF

; 6
:   .byte 15, $FF
:   .byte 15, $FF
:   .byte 15, $FF

:   .byte $FF
