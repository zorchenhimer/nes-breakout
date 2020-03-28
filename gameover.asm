; asmsyntax=ca65

go_Ded:
    .byte "Game Over", $00
go_Win:
    .byte "OMG you won", $00
go_Start:
    .byte "Press Start", $00

go_Palette:
    .byte $0F, $0F, $00, $10
    .byte $0F, $2A, $20, $10

Init_GameWon:
    lda #<go_Win
    sta AddressPointer0
    lda #>go_Win
    sta AddressPointer0+1
    jmp gameover_init

Init_GameOver:
    lda #<go_Ded
    sta AddressPointer0
    lda #>go_Ded
    sta AddressPointer0+1

gameover_init:
    .Disable_Drawing
    .NMI_Disable

.repeat 8, i
    lda go_Palette+i
    sta PaletteBuffer+i
    sta PaletteBufferSprites+i
.endrepeat

    ;lda #' '
    ;jsr FillNametable0
    jsr ClearAttrTable0

    jsr ClearSprites

    lda #2
    jsr LoadChrData

    jsr WriteTvAttr

    lda #ScreenIDs::Tv
    ldx #$20
    jsr LoadScreen

    bit $2002
    lda #$21
    sta $2006
    lda #$4B
    sta $2006

    ldy #0
:
    lda (AddressPointer0), y
    beq :+
    sta $2007
    iny
    jmp :-
:

    lda #$21
    sta $2006
    lda #$EA
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
    lda #InitIDs::Title
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

    .Update_PpuControl PPU_CTRL_NMI
    dec Sleeping
    rti
