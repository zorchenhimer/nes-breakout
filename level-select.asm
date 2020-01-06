; asmsyntax=ca65

ls_PalStack:
    .byte $19, $20, $20, $20

    nop
    nop

; Intial load of palettes
ls_LoadPalettes:
    ldx #0
@stack:
    lda ls_PalStack, x
    sta PaletteBufferSprites, x
    inx
    cpx #4
    bne @stack

; TODO: Read this from the animation data
    lda #1
    ldx #7
:
    sta ls_PaletteFrameTimer, x
    dex
    bpl :-
    rts

Init_LevelSelect:
    .NMI_Disable
    .Disable_Drawing

    jsr Clear_NonGlobalZp
    jsr ClearSprites

    jsr ls_LoadPalettes

    jsr ClearAttrTable0
    jsr ClearAttrTable1

    lda #5
    jsr LoadChrData

    bit $2000

    lda #$22
    sta $2006
    lda #$60
    sta $2006

    ; Draw a line above the box
    lda #$FD
    ldx #32
:
    sta $2007
    dex
    bne :-

    ; draw a box for the bottom non-map portion
    ldx #32
    ldy #10
    lda #$FE
:
    sta $2007
    dex
    bne :-
    ldx #32
    dey
    bne :-

    lda #$26
    sta $2006
    lda #$60
    sta $2006

    ldx #32
    lda #$FD
:
    sta $2007
    dex
    bne :-

    ; Draw a column on the right side of the bottom
    lda #$22
    sta $2006
    lda #$9F
    sta $2006

    .Update_PpuControl PPU_CTRL_NMI | PPU_CTRL_VERTICAL
    lda #$FF
    ldx #10
:
    sta $2007
    dex
    bne :-

    .Update_PpuControl PPU_CTRL_NMI

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    ; Draw the background
    ldx #0
:
    lda data_LS_BackgroundA, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundA+256, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundA+512, x
    sta $2007
    inx
    cpx #128
    bne :-

    lda #$24
    sta $2006
    lda #$00
    sta $2006

    ; Draw the second background
    ldx #0
:
    lda data_LS_BackgroundB, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundB+256, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundB+512, x
    sta $2007
    inx
    cpx #128
    bne :-

    ; Draw the level icons
    lda #0
    sta menu_DrawnSprites

    jsr ls_LoadSprites

    ; Setup sprite zero
    lda #$FD
    sta Sprites+1

    lda #$C0 ;x
    sta Sprites+3
    lda #151 ;y
    sta Sprites+0

    lda #0
    sta Sprites+2

    ; Load up current selection data
    lda menu_PrevLevel
    asl a
    tax

    lda data_Level_Progression_Idx, x
    sta ls_LevelProg
    lda data_Level_Progression_Idx+1, x
    sta ls_LevelProg+1

    ; load data into cursor section stuff
    ldy #0
    ldx #0
    stx ls_NumActiveLevels
:
    lda (ls_LevelProg), y
    bmi :+
    sta ls_ActiveLevels, x
    inc ls_NumActiveLevels
    inx
    iny
    jmp :-
:

    lda #LS_CURSOR_ANIM_FRAMES
    sta ls_cursorAnim
    lda #LS_CURSOR_COLOR_START
    sta ls_cursorColorBuff

    .NMI_Set NMI_LevelSelect
    jsr WaitForNMI

Frame_LevelSelect:
    jsr ReadControllers

    lda #BUTTON_RIGHT
    jsr ButtonPressedP1
    beq :+
    inc ls_SelectedLevel
    jmp @incOver
:
    lda #BUTTON_DOWN
    jsr ButtonPressedP1
    beq :+
    inc ls_SelectedLevel
:

@incOver:
    ; handle overflow
    lda ls_SelectedLevel
    cmp ls_NumActiveLevels
    bne :+
    lda #0
    sta ls_SelectedLevel
:

    lda #BUTTON_LEFT
    jsr ButtonPressedP1
    beq :+
    dec ls_SelectedLevel
    jmp @decUnder
:
    lda #BUTTON_UP
    jsr ButtonPressedP1
    beq :+
    dec ls_SelectedLevel
:

@decUnder:
    ; handle underflow
    lda ls_SelectedLevel
    bpl :+
    lda ls_NumActiveLevels
    sec
    sbc #1
    sta ls_SelectedLevel
:

    ; Go back to the main menu on SELECT
    lda #BUTTON_SELECT
    jsr ButtonPressedP1
    beq :+
    jsr WaitForNMI
    jmp Init_Title
:

    jsr ls_LoadCursor
    jsr ls_DoAnimations

    ;jsr WaitForSpriteZero
    ;lda #0
    ;sta $2005
    ;sta $2005

    jsr WaitForNMI
    jmp Frame_LevelSelect


ls_DoAnimations:
    ; Cursor palette animation
    dec ls_cursorAnim
    bne @noCursorAnim
    lda #LS_CURSOR_ANIM_FRAMES
    sta ls_cursorAnim

    inc ls_cursorColorBuff
    lda ls_cursorColorBuff
    cmp #LS_CURSOR_COLOR_END
    bne :+
    lda #LS_CURSOR_COLOR_START
    sta ls_cursorColorBuff
:
@noCursorAnim:

    lda #0
    sta menu_LoadedSprites
    sta menu_DrawnSprites
    sta IdxA

; Load visible sprite animations
@animLoop:
    lda IdxA
    jsr ls_SpriteAnimate

    inc IdxA
    lda IdxA
    cmp #SPRITE_OBJ_COUNT
    bne @animLoop

; scroll animation sprites
    ldx #0
    stx IdxA
@scrollLoop:
    lda IdxA
    jsr ls_SpriteScroll

    inc IdxA
    lda IdxA
    cmp menu_LoadedSprites
    bne @scrollLoop

    ; sprite ID -> offset
    lda menu_DrawnSprites
    clc
    adc #LEVELSELECT_SPRITE_OFFSET
    asl a
    asl a
    tax

    lda #$FF
:
    sta Sprites, x
    inx
    bne :-

; Animate all palettes
    ldx #0
    stx IdxA
@palLoop:
    lda IdxA
    jsr ls_PaletteAnimate

    inc IdxA
    lda IdxA
    cmp #PAL_ANIM_COUNT
    bne @palLoop
    rts

NMI_LevelSelect:

    jsr WritePalettes

    .WriteSprites
    .Update_PpuMask PPU_MASK_ON
    .Update_PpuControl PPU_CTRL_NMI

    ;.SetScroll_Var 0
    bit $2000
    lda menu_ScrollValue
    sta $2005
    lda #0
    sta $2005

    lda #$FF
    sta Sleeping

    rti

; jsr to AddressPointer0
JsrPointer:
    lda #>@end
    pha
    lda #<@end
    pha

    jmp (AddressPointer0)

@end:
    nop
    rts

; PPU Address in AddressPointer0
; Width of tiles in TmpX
; Height of tiles in TmpY
; Tile ID start in TmpW
ls_DrawLevelIcon:
    ;ldy TmpY
@row:
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ldy TmpW
    ldx TmpX
@col:
    sty $2007
    iny
    dex
    bne @col

    dec TmpY
    beq @done

    ; Get the start ID of the next tile row
    lda TmpW
    clc
    adc #16
    sta TmpW
    tay

    ; Increment address to next row
    lda AddressPointer0
    clc
    adc #32
    sta AddressPointer0

    bcc :+
    inc AddressPointer0+1
:
    jmp @row

@done:
    rts

; Animate palettes
; Palette animation index in A
ls_PaletteAnimate:
    asl a
    tax
    lda data_PaletteAnim_List+0, x
    sta AddressPointer0+0
    lda data_PaletteAnim_List+1, x
    sta AddressPointer0+1

    ldy #0
    ; Palette Index
    lda (AddressPointer0), y
    tax
    asl a
    asl a
    sta TmpY

    dec ls_PaletteFrameTimer, x
    bne @noAnim

    inc ls_PaletteFrames, x
    lda ls_PaletteFrames, x

    ; check for overflow
    ldy #1
    cmp (AddressPointer0), y
    bcc :+
    lda #0
    sta ls_PaletteFrames, x
:

    iny
    lda (AddressPointer0), y
    sta ls_PaletteFrameTimer, x

@noAnim:
    lda ls_PaletteFrames, x
    asl a
    asl a
    clc
    adc #3
    tay

    ldx #0
:
    lda (AddressPointer0), y
    sta ls_PalTmp, x
    iny
    inx
    cpx #4
    bne :-

    ldy TmpY    ; reload palette offset
    ldx #0
:
    lda ls_PalTmp, x
    sta PaletteBuffer, y
    iny
    inx
    cpx #4
    bne :-

    rts

; Sprite ID in a
; Read the sprite data from RAM, manipulate the
; coords, and write it to OAM if it is on screen.
ls_SpriteScroll:
    tax
    lda ls_SpriteX, x
    ; TODO: Set carry depending on X's 9th bit? (bit 3 of flags)
    sec
    sbc menu_ScrollValue
    bcs :+
    ; Off the left side of the screen; don't draw.
    rts
:
    sta TmpX
    lda menu_DrawnSprites
    clc
    ; increment past sprite zero and cursor sprites
    adc #LEVELSELECT_SPRITE_OFFSET
    asl a
    asl a
    tay
    ;sta TmpZ    ; Sprite offset in OAM
    lda ls_SpriteY, x
    sta Sprites, y
    iny

    lda ls_SpriteTiles, x
    sta Sprites, y
    iny

    ; Palette is in lower two bits
    lda ls_SpriteFlags, x
    ;and #$03
    sta Sprites, y
    iny

    lda TmpX
    sta Sprites, y

    inc menu_DrawnSprites
    rts

; Initial sprite loading stuff
; Loads the frame rate info into RAM
ls_LoadSprites:
    ldx #0
:
    ; ID -> DWORD index
    txa
    asl a
    asl a
    tay

    lda data_SpriteObject_List+0, y
    sta AddressPointer0+0
    lda data_SpriteObject_List+1, y
    sta AddressPointer0+1

    ; frame rate
    ldy #1
    lda (AddressPointer0), y
    sta ls_SpriteFrameTimer, x
    inx

    cpx #SPRITE_OBJ_COUNT
    bne :-
    rts

; Animate a given sprite.  If it is not time to
; animate this frame, write the last frame again.
ls_SpriteAnimate:
    sta TmpX    ; A holds the obj sprite index

    ; ID -> DWORD index
    asl a
    asl a
    tax

    ; sprite obj definition
    lda data_SpriteObject_List, x
    sta AddressPointer0+0
    inx
    lda data_SpriteObject_List, x
    sta AddressPointer0+1
    inx

    ; Base X/X
    lda data_SpriteObject_List, x
    sta tmp_BaseX
    inx
    lda data_SpriteObject_List, x
    sta tmp_BaseY

    ; reload sprite obj ID
    ldx TmpX

    ; check if it's time to animate
    dec ls_SpriteFrameTimer, x
    bne @noAnim    ; not time to animate

    ; Update frame number
    inc ls_SpriteFrames, x
    lda ls_SpriteFrames, x

    ; frame count in the definition
    ldy #2
    cmp (AddressPointer0), y

    bcc :+
    ; handle overflow
    lda #0
    sta ls_SpriteFrames, x
:

    ; Reset the framerate counter
    ldy #1
    lda (AddressPointer0), y
    sta ls_SpriteFrameTimer, x

@noAnim:
    ; The animation data still needs to be written
    ; on every frame, the only difference is not
    ; updating the frame number.

    ; animation type
    ldy #0
    lda (AddressPointer0), y
    beq @ls_SpriteAnimate_Move
    iny
    ; static "animation"

    ; Sprite count
    lda (AddressPointer0), y
    sta IdxC
    iny

    ; Tile data pointer
    lda (AddressPointer0), y
    sta AddressPointer1+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer1+1
    iny

    ; Attribute data pointer
    lda (AddressPointer0), y
    sta AddressPointer2+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer2+1
    iny

    ; X data pointer
    lda (AddressPointer0), y
    sta AddressPointer3+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer3+1
    iny

    ; Y data pointer
    lda (AddressPointer0), y
    sta AddressPointer4+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer4+1
    iny

    ; individual sprites in obj
    lda #0
    sta IdxB    ; current sprite in obj
@spriteLoopA:
    ldy IdxB
    ldx menu_LoadedSprites

    lda (AddressPointer3), y
    clc
    adc tmp_BaseX
    sta ls_SpriteX, x

    lda (AddressPointer4), y
    clc
    adc tmp_BaseY
    sta ls_SpriteY, x

    lda (AddressPointer1), y
    sta ls_SpriteTiles, x

    lda (AddressPointer2), y
    sta ls_SpriteFlags, x

    inx
    stx menu_LoadedSprites

    inc IdxB
    lda IdxB
    cmp IdxC
    bne @spriteLoopA
    rts

@ls_SpriteAnimate_Move:
    ldy #2
    lda (AddressPointer0), y
    sta IdxC    ; sprite count in obj

    ldy #4
    ; Tile data pointer
    lda (AddressPointer0), y
    sta AddressPointer1+0
    iny

    lda (AddressPointer0), y
    sta AddressPointer1+1
    iny

    ; Attribute data pointer
    lda (AddressPointer0), y
    sta AddressPointer2+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer2+1
    iny

    ; X data pointer
    lda (AddressPointer0), y
    sta AddressPointer3+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer3+1
    iny

    ; Y data pointer
    lda (AddressPointer0), y
    sta AddressPointer4+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer4+1
    iny

    ; Frame X data pointer
    lda (AddressPointer0), y
    sta AddressPointer5+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer5+1
    iny

    ; Frame Y data pointer
    lda (AddressPointer0), y
    sta AddressPointer6+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer6+1
    iny

    ; Reload the current frame index
    lda ls_SpriteFrames, x
    tay

    ; Add base Y offset to frame X offset
    lda (AddressPointer5), y
    clc
    adc tmp_BaseX
    sta tmp_BaseX

    ; Add base Y offset to frame Y offset
    lda (AddressPointer6), y
    clc
    adc tmp_BaseY
    sta tmp_BaseY

    ; indiviual sprites in the obj
    lda #0
    sta IdxB    ; current sprite in obj
@spriteLoop:
    ; load sprite IDX in OBJ
    ldy IdxB

    ; foreach sprite in obj, write its X coord to RAM
    lda (AddressPointer3), y
    clc
    adc tmp_BaseX
    sta tmp_SpriteX

    ; foreach sprite in obj, write its Y coord to RAM
    lda (AddressPointer4), y
    clc
    adc tmp_BaseY
    sta tmp_SpriteY

    ; sprite tile
    lda (AddressPointer1), y
    sta tmp_SpriteTile

    ; sprite Attr
    lda (AddressPointer2), y
    sta tmp_SpriteFlags

    ; copy values from tmp
    ldx menu_LoadedSprites

    lda tmp_SpriteX
    sta ls_SpriteX, x
    lda tmp_SpriteY
    sta ls_SpriteY, x

    lda tmp_SpriteTile
    sta ls_SpriteTiles, x
    lda tmp_SpriteFlags
    sta ls_SpriteFlags, x

    inx
    stx menu_LoadedSprites

    ; increment current sprite in OBJ
    inc IdxB
    lda IdxB
    cmp IdxC    ; cmp to total sprites in OBJ
    bne @spriteLoop
    rts

LS_CURSOR_1 = Sprites + (4 * 1)
LS_CURSOR_2 = Sprites + (4 * 2)
LS_CURSOR_3 = Sprites + (4 * 3)
LS_CURSOR_4 = Sprites + (4 * 4)
LS_CURSOR_PAL = $03

; Load cursor values given the currently selected level.
ls_LoadCursor:
    ldx ls_SelectedLevel
    lda ls_ActiveLevels, x
    ; index into data_LevelSelect_Cursor is in A

    ; index -> offset
    asl a
    asl a
    tay

    ;; Position and size
    ; Width/Height
    lda data_LevelSelect_Cursor + 2, y
    sta TmpX
    lda data_LevelSelect_Cursor + 3, y
    sta TmpY

    ; X/Y
    ldx data_LevelSelect_Cursor, y
    lda data_LevelSelect_Cursor + 1, y
    tay
    ; Fall into next routine

; Draw cursor at a given X/Y coordinate.
; X is in X regsiter
; Y is in Y register
; Width in TmpX
; Height in TmpY
ls_DrawCursorXY:
    ; X for left side
    stx LS_CURSOR_1 + 3
    stx LS_CURSOR_3 + 3

    ; Y for top
    sty LS_CURSOR_1 + 0
    sty LS_CURSOR_2 + 0

    ; X for right side
    txa
    clc
    adc TmpX
    sta LS_CURSOR_2 + 3
    sta LS_CURSOR_4 + 3

    ; Y for bottom
    tya
    clc
    adc TmpY
    sta LS_CURSOR_3 + 0
    sta LS_CURSOR_4 + 0

    ;; Tile
    lda #CURSOR_TILE
    sta LS_CURSOR_1 + 1
    sta LS_CURSOR_2 + 1
    sta LS_CURSOR_3 + 1
    sta LS_CURSOR_4 + 1

    ;; Attributes
    ; top left
    lda #LS_CURSOR_PAL
    sta LS_CURSOR_1 + 2

    ; top right
    lda #LS_CURSOR_PAL | $40
    sta LS_CURSOR_2 + 2

    ; bottom left
    lda #LS_CURSOR_PAL | $80
    sta LS_CURSOR_3 + 2

    ; bottom right
    lda #LS_CURSOR_PAL | $C0
    sta LS_CURSOR_4 + 2

    ;; Scroll screen
    ldx ls_SelectedLevel
    ldy ls_ActiveLevels, x
    lda data_LevelSelect_CursorScroll, y
    sta menu_ScrollValue
    rts

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
    .byte $0F, $20, $00, $00
    .byte $0F, $00, $20, $00
    .byte $0F, $00, $00, $20
    ;.byte $0F, $0F, $20, $0F

; List of all the sprite objects
; A "sprite object" is a meta-sprite for animation.
data_SpriteObject_List:
    .word data_SpriteObj_Def_Stack
        .byte 80, 35    ; base X/Y
    .word data_SpriteObj_Def_Stack
        .byte 80, 99    ; base X/Y

    .word data_SpriteObj_Def_Modem
        .byte 136, 16
    .word data_SpriteObj_Def_Modem
        .byte 128, 64
    .word data_SpriteObj_Def_Modem
        .byte 128, 128

    .word data_SpriteObj_Def_Sat
        .byte 168, 55
    .word data_SpriteObj_Def_Sat
        .byte 168, 111

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
    .byte 81, 30, 14, 17
    .byte 81, 94, 14, 17

    ; 3
    .byte 135, 14,  10, 10
    .byte 127, 62,  10, 10
    .byte 127, 126, 10, 10

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
    .byte 0
    .byte 0
    .byte 0

    ; 4
    .byte 20
    .byte 20

    ; 5
    .byte 20
    .byte 20
    .byte 20
    .byte 20

    ; 6
    .byte 40
    .byte 40
    .byte 40

    ; 7
    .byte 80

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

.include "lsbg.i"
