; asmsyntax=ca65

go_Text:
    .byte "Game Over", $00
go_Start:
    .byte "Press Start", $00

go_Palette:
    .byte $0F, $0F, $0F, $2A

Init_GameOver:
    .Disable_Drawing
    .NMI_Disable

.repeat 4, i
    lda go_Palette+i
    sta PaletteBuffer+i
    sta PaletteBufferSprites+i
.endrepeat

    lda #' '
    jsr FillNametable0
    jsr ClearAttrTable0

    jsr ClearSprites

    lda #2
    jsr LoadChrData

    bit $2002
    lda #$21
    sta $2006
    lda #$4C
    sta $2006

    ldx #0
:
    lda go_Text, x
    beq :+
    sta $2007
    inx
    jmp :-
:

    lda #$23
    sta $2006
    lda #$2B
    sta $2006

    ldx #0
:
    lda go_Start, x
    beq :+
    sta $2007
    inx
    jmp :-
:

Frame_GameOver:
    .NMI_Set NMI_GameOver

    lda #PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN
    sta PpuControl

    jsr ReadControllers

    lda #BUTTON_START
    jsr ButtonPressedP1
    beq :+

    jsr WaitForNMI
    lda #0
    jmp JumpToInit
:

    jsr WaitForNMI
    jmp Frame_GameOver

NMI_GameOver:
    jsr WriteSprites
    jsr WritePalettes

    .Update_PpuMask PPU_MASK_ON | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND

    lda #0
    sta $2005
    sta $2005

    .Update_PpuControl_Var PpuControl
    dec Sleeping
    rti
