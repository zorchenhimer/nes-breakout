; asmsyntax=ca65

Init_LevelSelect:
    ; TODO: load palletes first

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
    ; draw a line for the bottom non-map portion
    lda #$22
    sta $2006
    lda #$80
    sta $2006

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

    ; Draw the level icons
    lda #0
    sta IdxA
@levelIconLoop:
    lda IdxA
    asl a
    tay

    lda data_LevelIcons_Addr+1, y
    beq @done

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

@done:

    .NMI_Set NMI_LevelSelect
    jsr WaitForNMI
:
    jmp :-

NMI_LevelSelect:

    .WriteSprites
    .Update_PpuMask PPU_MASK_ON

    lda #$80
    sta $2000

    .SetScroll 0

    rti


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



