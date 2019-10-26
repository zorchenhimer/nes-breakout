; asmsyntax=ca65

ls_SpritePalettes:
    .byte $0F, $34, $20, $20

    nop
    nop

Init_LevelSelect:
    ; TODO: load palletes first

    ldx #0
    bit $2000
    lda #$3F
    sta $2006
    lda #$10
    sta $2006

:
    lda ls_SpritePalettes, x
    sta $2007
    inx
    cpx #4
    bne :-

    .NMI_Disable
    .Disable_Drawing

    jsr Clear_NonGlobalZp
    jsr ClearSprites

    lda #$FF
    jsr FillNametable0
    jsr FillNametable1

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

    ; Draw the level icons
    ldx #0
@iconDataLoop:
    lda data_LevelIcons, x
    beq @iconDone

    lda data_LevelIcons+1, x
    sta $2006
    lda data_LevelIcons, x
    sta $2006
    inx
    inx

    ; data length
    ldy data_LevelIcons, x
    inx
    lda data_LevelIcons, x
    sta TmpX
:
    lda TmpX
    inc TmpX
    sta $2007
    dey
    bne :-
    inx
    jmp @iconDataLoop

@iconDone:
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

    .NMI_Set NMI_LevelSelect
    jsr WaitForNMI

Frame_LevelSelect:
    jsr ReadControllers

    lda #BUTTON_RIGHT
    and controller1
    beq :+
    inc menu_ScrollValue
:

    lda #BUTTON_LEFT
    and controller1
    beq :+
    dec menu_ScrollValue
:

    lda #0
    sta menu_LoadedSprites
    sta menu_DrawnSprites
    sta IdxA

@animLoop:
    lda IdxA
    jsr ls_SpriteAnimate

    inc IdxA
    lda IdxA
    cmp #SPRITE_OBJ_COUNT
    bne @animLoop

; scroll all sprites
    ldx #0
    stx IdxA
@scrollLoop:
    lda IdxA
    jsr ls_SpriteScroll

    inc IdxA
    lda IdxA
    cmp #LS_SPRITES_TO_LOAD
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

    jsr WaitForSpriteZero
    lda #0
    sta $2005
    sta $2005

    jsr WaitForNMI
    jmp Frame_LevelSelect

NMI_LevelSelect:

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
    ldy #0
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
    ldy #0
    lda (AddressPointer0), y
    sta ls_SpriteFrameTimer, x

@noAnim:
    ; The animation data still needs to be written
    ; on every frame, the only difference is not
    ; updating the frame number.

    ldy #1
    lda (AddressPointer0), y
    sta IdxC    ; sprite count in obj

    ldy #3
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

; List of all the sprite objects
; A "sprite object" is a meta-sprite for animation.
data_SpriteObject_List:
    .word data_SpriteObj_Def_Stack
        .byte 80, 35    ; base X/Y
    .word data_SpriteObj_Def_Stack
        .byte 80, 99    ; base X/Y

SPRITE_OBJ_COUNT = (* - data_SpriteObject_List) / 4

; TODO: find a way to calculate this
LS_SPRITES_TO_LOAD = 6

data_SpriteObj_Def_Stack:
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
