; asmsyntax=ca65

.scope anim_StackCoords
    Y_Coords:   .byte 0, 8, 16 ; y, for frame
    Len:        .byte * - Y_Coords
    Tile:       .byte $33
    Flags:      .byte 0

    BaseX:      .byte 83, 97
    BaseY:      .byte 33, 33
    Count:      .byte * - BaseY
    ;.byte 83, 33, $33, 0 ; stack
    ;.byte 97, 33, $33, 0
.endscope

.scope anim_ServerCoords
    Y_Coords: .byte 0, 8, 16 ; y
    Len:      .byte * - Y_Coords
.endscope

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
    sta menu_DrawnSprites
    sta IdxA
:
    lda IdxA
    jsr ls_SpriteAnimate

    lda IdxA
    jsr ls_SpriteScroll

    inc IdxA
    lda IdxA
    cmp #LS_SPRITES_TO_LOAD
    bne :-

    ldx menu_DrawnSprites
:
    cpx #LS_SPRITES_TO_LOAD  ; max number of sprites
    beq :+

    ; Index -> offset
    txa
    clc
    adc #LEVELSELECT_SPRITE_OFFSET
    asl a
    asl a
    tay

    lda #$FF
    sta Sprites+0, y
    sta Sprites+1, y
    sta Sprites+2, y
    sta Sprites+3, y
    inx
    jmp :-
:

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
anim_StackSpriteA:
    ;lda #whatever
;    ldx anim_StackA;+StackAnim::Frame
;
;    lda anim_StackCoords::Y_Coords, x
;    sta anim_StackA+StackAnim::Y0
;
;    ; loop through the tiles in sprite
;    ldy #0
;:
;    lda anim_StackCoords::BaseX, y
;    sta anim_StackA::X1, y
;    iny
;    cpy #3
;    bne :-

    jmp anim_StackSprite_real

anim_StackSpriteB:
    ;lda #other

anim_StackSprite_real:
    ; ...
    rts

; Sprite ID in a
; Read the sprite data from RAM, manipulate the
; coords, and write it to OAM if it is on screen.
ls_SpriteScroll:
    tax
    lda ls_SpriteX, x
    ; TODO: Set carry depending on X's 9th bit?
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
    and #$03
    sta Sprites, y
    iny

    lda TmpX
    sta Sprites, y

    inc menu_DrawnSprites
    rts

; Initial sprite loading stuff
ls_LoadSprites:
    ldx #0
:
    lda data_LevelSprites_FrameRate, x
    sta ls_SpriteFrameTimer, x
    inx
    cpx #LS_SPRITES_TO_LOAD
    bne :-

    rts

; Animate a given sprite.  If it is not time to
; animate this frame, write the last frame again.
ls_SpriteAnimate:
    sta TmpX    ; A holds the sprite index
    tax

    ; shift to a double-word (4-byte) data index
    asl a
    asl a
    tay

    ; check if it's time to animate
    dec ls_SpriteFrameTimer, x
    bne @noAnim    ; not time to animate

    ; Update frame number
    inc ls_SpriteFrames, x
    lda ls_SpriteFrames, x
    cmp data_LevelSprites_FrameCount, x
    bcc :+
    lda #0
    sta ls_SpriteFrames, x
:

    ; Reset the framerate counter
    lda data_LevelSprites_FrameRate
    sta ls_SpriteFrameTimer, x

@noAnim:
    ; The animation data still needs to be written
    ; on every frame, the only difference is not
    ; updating the frame number.

    lda ls_SpriteFrames, x  ; load current frame idx
    tax

    lda data_LevelSprites_meta, y
    clc
    adc data_LevelSprites_FrameData_X, x
    sta tmp_SpriteX
    iny

    lda data_LevelSprites_meta, y
    clc
    adc data_LevelSprites_FrameData_Y, x
    sta tmp_SpriteY
    iny

    ldx TmpX    ; get the sprite ID again
    ; increment the frame and handle rollover

    lda data_LevelSprites_meta, y
    sta tmp_SpriteTile
    iny

    lda #0
    sta tmp_SpriteFlags

    ; copy values from tmp
    lda tmp_SpriteX
    sta ls_SpriteX, x
    lda tmp_SpriteY
    sta ls_SpriteY, x

    lda tmp_SpriteTile
    sta ls_SpriteTiles, x
    lda tmp_SpriteFlags
    sta ls_SpriteFlags, x

@end:
    rts

; Start PPU address
data_LevelIcons_Addr:
    .word $2104

    .word $208A
    .word $218A

    .word $2050
    .word $2110
    .word $2210

    .word $20B5
    .word $2195

    .word $205C
    .word $20FC
    .word $219C
    .word $221C

    .word $0000


; Animation data
;
data_LevelSprites_meta:
    ;.byte X, Y, ID, X's 9th/Palette
    .byte 80, 35, $33, 0 ; stack (top)
    .byte 88, 35, $34, 0
    .byte 96, 35, $35, 0

    .byte 80, 99, $33, 0 ; stack (bottom)
    .byte 88, 99, $34, 0
    .byte 96, 99, $35, 0

data_LevelSprites_FrameCount:
    .byte 4
    .byte 4
    .byte 4

    .byte 4
    .byte 4
    .byte 4

; whole frames for now
data_LevelSprites_FrameRate:
    .byte 10
    .byte 10
    .byte 10

    .byte 10
    .byte 10
    .byte 10

; Relative X coordinate values
data_LevelSprites_FrameData_X:
    .byte 0, 0, 0, 0
    .byte 0, 0, 0, 0
    .byte 0, 0, 0, 0

    .byte 0, 0, 0, 0
    .byte 0, 0, 0, 0
    .byte 0, 0, 0, 0

; Relative Y coordinate values
data_LevelSprites_FrameData_Y:
    .byte 0, 6, 12, 6
    .byte 0, 6, 12, 6
    .byte 0, 6, 12, 6

    .byte 0, 6, 12, 6
    .byte 0, 6, 12, 6
    .byte 0, 6, 12, 6

LS_SPRITES_TO_LOAD = 6

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
