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
    lda #0
    sta IdxA
@levelIconLoop:
    lda IdxA
    asl a
    tay

    lda data_LevelIcons_Addr+1, y
    beq @iconDone

    sta AddressPointer0+1
    lda data_LevelIcons_Addr+0, y
    sta AddressPointer0+0

    tya
    asl a
    tay

    lda data_LevelIcons_Meta+0, y
    sta TmpX
    lda data_LevelIcons_Meta+1, y
    sta TmpY
    lda data_LevelIcons_Meta+2, y
    sta TmpW

    jsr ls_DrawLevelIcon
    inc IdxA
    jmp @levelIconLoop

@iconDone:
    lda #0
    sta menu_DrawnSprites

    ;jsr ls_LoadSprites

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
    cpx #3  ; max number of sprites
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

    ;lda #$80
    ;sta $2000

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
    adc #LEVELSELECT_SPRITE_OFFSET  ; increment past sprite zero and cursor sprites
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

;ls_LoadSprites:
ls_SpriteAnimate:
    sta TmpX
    tax
    asl a
    asl a
    tay

    ;ldy #0
    ;ldx #0
;@loop:
    stx TmpX

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

    lda data_LevelSprites_meta, y
    sta tmp_SpriteTile
    iny

    lda #0
    sta tmp_SpriteFlags

    ldx TmpX    ; get the sprite ID again

    ; increment the frame and handle rollover
    inc ls_SpriteFrames, x
    lda ls_SpriteFrames, x
    cmp data_LevelSprites_FrameCount, x
    bcc :+
    lda #0
    sta ls_SpriteFrames, x
:

    ; copy values from tmp
    lda tmp_SpriteX
    sta ls_SpriteX, x
    lda tmp_SpriteY
    sta ls_SpriteY, x

    lda tmp_SpriteTile
    sta ls_SpriteTiles, x
    lda tmp_SpriteFlags
    sta ls_SpriteFlags, x

    ;iny
    ;inx
    ;cpx #LS_SPRITES_TO_LOAD
    ;bne @loop

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

; Width, Height, Tile ID, padding
data_LevelIcons_Meta:
    .byte 3, 2, $00, 0  ; bricks

    .byte 3, 3, $03, 0  ; stack
    .byte 3, 3, $03, 0

    .byte 2, 2, $0B, 0  ; modem
    .byte 2, 2, $0B, 0
    .byte 2, 2, $0B, 0

    .byte 3, 3, $0D, 0  ; satelites
    .byte 3, 3, $0D, 0

    .byte 2, 2, $06, 0  ; servers
    .byte 2, 2, $06, 0
    .byte 2, 2, $06, 0
    .byte 2, 2, $06, 0

data_LevelSprites_meta:
    ;.byte X, Y, ID, X's 9th/Palette
    .byte 80, 35, $33, 0 ; stack
    .byte 88, 35, $34, 0
    .byte 96, 35, $35, 0

data_LevelSprites_FrameCount:
    .byte 4
    .byte 4
    .byte 4

; Relative X coordinate values
data_LevelSprites_FrameData_X:
    .byte 0, 0, 0, 0
    .byte 0, 0, 0, 0
    .byte 0, 0, 0, 0

; Relative Y coordinate values
data_LevelSprites_FrameData_Y:
    .byte 0, 6, 12, 6
    .byte 0, 6, 12, 6
    .byte 0, 6, 12, 6

LS_SPRITES_TO_LOAD = 3

pointers_levelAnim:
    .word anim_StackSpriteA
    .word anim_StackSpriteB

COUNT_ANIM_POINTER = * - pointers_levelAnim
