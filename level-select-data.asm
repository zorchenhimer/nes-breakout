; asmsyntax=ca65

;;
;; All the hand-written data for the level select screen
;;

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
        .byte 112, 35   ; base X/Y
        .byte 0         ; Nametable
    .word data_SpriteObj_Def_Stack
        .byte 104, 115    ; base X/Y
        .byte 0         ; Nametable

    .word data_SpriteObj_Def_Modem
        .byte 240, 16
        .byte 0
    .word data_SpriteObj_Def_Modem
        .byte 184, 64
        .byte 0
    .word data_SpriteObj_Def_Modem
        .byte 168, 112
        .byte 0

    .word data_SpriteObj_Def_Sat
        .byte 248, 63
        .byte 0
    .word data_SpriteObj_Def_Sat
        .byte 232, 127
        .byte 0

    .word data_SpriteObj_Def_Rack
        .byte 64, 31
        .byte 1
    .word data_SpriteObj_Def_Rack
        .byte 80, 63
        .byte 1
    .word data_SpriteObj_Def_Rack
        .byte 96, 95
        .byte 1
    .word data_SpriteObj_Def_Rack
        .byte 64, 127
        .byte 1

SPRITE_OBJ_COUNT = (* - data_SpriteObject_List) / 5

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

data_SpriteObj_Def_Rack:
    .byte 0         ; animation type
    .byte 10        ; frame rate
    .byte 2         ; sprite count
    .byte 4         ; frame count

    .word data_SpriteObj_04Tiles
    .word data_SpriteObj_04Attr
    .word data_SpriteObj_04X
    .word data_SpriteObj_04Y
    .word data_SpriteObj_04FrameX
    .word data_SpriteObj_04FrameY

data_SpriteObj_04Tiles:
    .byte $08, $18
data_SpriteObj_04Attr:
    .byte 0, 0
data_SpriteObj_04X:
    .byte 0, 0
data_SpriteObj_04Y:
    .byte 0, 8

data_SpriteObj_04FrameX:
    .byte 0, 0, 1, 1
data_SpriteObj_04FrameY:
    .byte 0, 1, 1, 0

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
    .byte 116, 45, 20, 20
    .byte 100, 109, 20, 20

    ; 5
    .byte 188, 29, 12, 12
    .byte 164, 61, 12, 12
    .byte 180, 93, 12, 12
    .byte 148, 125, 12, 12

    ; 6
    .byte 159, 37, 12, 12
    .byte 167, 77, 12, 12
    .byte 143, 109, 12, 12

    ; 7
    .byte 207, 61, 20, 20

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
    .byte 130
    .byte 130

    ; 5
    .byte 130
    .byte 170
    .byte 170
    .byte 170

    ; 6
    .byte 255
    .byte 255
    .byte 255

    ; 7
    .byte 255

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

; Quadrants of the attribute data for better readability
TR_BOTL = %0001_0000
TR_BOTR = %0100_0000
TR_TOPL = %0000_0001
TR_TOPR = %0000_0100

trace_1_2a:
    .word $23C9
    .byte TR_BOTL | TR_BOTR
    .word $23CA
    .byte TR_BOTL | TR_BOTR | TR_TOPL | TR_TOPR
    .word $23CB
    .byte TR_TOPL
    .word $0000 ; word cuz we need the high byte zero

trace_1_2b:
    .word $23D1
    .byte TR_BOTR
    .word $23D9
    .byte TR_TOPR
    .word $23DA
    .byte TR_BOTL | TR_BOTR | TR_TOPL | TR_TOPR
    .word $23DB
    .byte TR_TOPL
    .word $0000

trace_2a_3a:
    .word $23C3
    .byte TR_BOTR | TR_TOPR
    .word $23C4
    .byte TR_BOTL | TR_BOTR | TR_TOPL | TR_TOPR
    .word $23C5
    .byte TR_BOTL | TR_BOTR
    .word $23CD
    .byte TR_TOPR
    .word $23C6
    .byte TR_BOTL | TR_BOTR
    .word $23CE
    .byte TR_TOPL | TR_TOPR
    .word $23C7
    .byte TR_BOTL
    .word $0000

trace_2a_3b:
    .word $23CB
    .byte TR_BOTL
    .word $23D3
    .byte TR_TOPL | TR_TOPR
    .word $23D4
    .byte TR_TOPL | TR_TOPR
    .word $23D5
    .byte TR_TOPL
    .word $23CC
    .byte TR_BOTR
    .word $23CD
    .byte TR_BOTL | TR_BOTR
    .word $0000

trace_2b_3b:
    .word $23DB
    .byte TR_TOPR
    .word $23D3
    .byte TR_BOTR
    .word $23D4
    .byte TR_BOTL | TR_BOTR
    .word $23D5
    .byte TR_BOTL | TR_BOTR
    .word $0000

trace_2b_3c:
    .word $23DC
    .byte TR_BOTL | TR_BOTR
    .word $23E4
    .byte TR_TOPR
    .word $23E5
    .byte TR_TOPL
    .word $0000

trace_3a_5a:
    .word $27C0
    .byte TR_BOTL | TR_BOTR
    .word $27C1
    .byte TR_BOTL | TR_BOTR
    .word $27C2
    .byte TR_BOTL
    .word $0000

trace_3a_4a:
    .word $23CF
    .byte TR_TOPR
    .word $27C8
    .byte TR_TOPL
    .word $0000

trace_3b_4a:
    .word $23CE
    .byte TR_BOTL | TR_BOTR
    .word $23CF
    .byte TR_BOTL
    .word $23D7
    .byte TR_TOPL | TR_TOPR
    .word $0000

trace_3b_4b:
    .word $23D6
    .byte TR_BOTL | TR_BOTR
    .word $23DE
    .byte TR_TOPR
    .word $23DF
    .byte TR_TOPL
    .word $0000

trace_3c_4b:
    .word $23DD
    .byte TR_TOPR
    .word $23DE
    .byte TR_TOPL | TR_BOTL
    .word $23E6
    .byte TR_TOPL | TR_TOPR
    .word $23E7
    .byte TR_TOPL
    .word $0000

trace_4a_5b:
    .word $27C8
    .byte TR_BOTR
    .word $27C9
    .byte TR_BOTL
    .word $27D1
    .byte TR_TOPL | TR_TOPR
    .word $27D2
    .byte TR_TOPL
    .word $0000

trace_4a_5c:
    .word $27D0
    .byte TR_TOPR | TR_BOTR
    .word $27D8
    .byte TR_TOPR | TR_BOTR
    .word $27D9
    .byte TR_BOTL | TR_BOTR
    .word $27DA
    .byte TR_BOTL | TR_BOTR
    .word $27DB
    .byte TR_BOTL
    .word $0000

trace_4b_5b:
    .word $23DF
    .byte TR_TOPR
    .word $23D7
    .byte TR_BOTR
    .word $27D0
    .byte TR_BOTL
    .word $27D1
    .byte TR_BOTL | TR_BOTR
    .word $27D2
    .byte TR_BOTL | TR_BOTR
    .word $0000

trace_4b_5c:
    .word $27D8
    .byte TR_TOPL | TR_BOTL
    .word $27D9
    .byte TR_TOPL | TR_TOPR
    .word $27DA
    .byte TR_TOPL | TR_TOPR
    .word $0000

trace_4b_5d:
    .word $27E0
    .byte TR_TOPL | TR_TOPR
    .word $27E1
    .byte TR_TOPL | TR_TOPR
    .word $0000

trace_5a_7:
    .word $27CA
    .byte TR_TOPR
    .word $27C2
    .byte TR_BOTR
    .word $27C3
    .byte TR_BOTL | TR_BOTR
    .word $27C4
    .byte TR_BOTL | TR_BOTR
    .word $27C5
    .byte TR_BOTL | TR_BOTR
    .word $27C6
    .byte TR_BOTL | TR_BOTR
    .word $27C7
    .byte TR_BOTL
    .word $27CF
    .byte TR_BOTL | TR_TOPL
    .word $0000

trace_5b_6a:
    .word $27CA
    .byte TR_BOTR
    .word $27CB
    .byte TR_TOPL | TR_TOPR | TR_BOTL
    .word $27CC
    .byte TR_TOPL | TR_TOPR
    .word $0000

trace_5b_6b:
    .word $27D3
    .byte TR_TOPL
    .word $27D4
    .byte TR_TOPL | TR_TOPR
    .word $27D5
    .byte TR_TOPL
    .word $0000

trace_5c_6a:
    .word $27D3
    .byte TR_TOPR | TR_BOTL | TR_BOTR
    .word $27CB
    .byte TR_BOTR
    .word $27CC
    .byte TR_BOTR | TR_BOTL
    .word $0000

trace_5c_6b:
    .word $27DB
    .byte TR_TOPR
    .word $27DC
    .byte TR_TOPR | TR_TOPL
    .word $27DD
    .byte TR_TOPL
    .word $0000

trace_5d_6b:
    .word $27E2
    .byte TR_BOTL | TR_BOTR
    .word $27E3
    .byte TR_BOTL | TR_BOTR
    .word $27E4
    .byte TR_BOTL | TR_BOTR
    .word $27E5
    .byte TR_BOTL | TR_BOTR | TR_TOPR
    .word $27DD
    .byte TR_TOPR
    .word $0000

trace_5d_6c:
    .word $27E2
    .byte TR_TOPR
    .word $27E3
    .byte TR_TOPR | TR_TOPL
    .word $27E4
    .byte TR_TOPR | TR_TOPL
    .word $0000

trace_6a_7:
    .word $27CD
    .byte TR_TOPR
    .word $27CE
    .byte TR_TOPR | TR_TOPL | TR_BOTR
    .word $0000

trace_6b_7:
    .word $27D5
    .byte TR_TOPR
    .word $27D6
    .byte TR_TOPL
    .word $0000

trace_6c_7:
    .word $27DD
    .byte TR_BOTL | TR_BOTR
    .word $27DE
    .byte TR_BOTL | TR_TOPL
    .word $27D6
    .byte TR_BOTL
    .word $0000

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
