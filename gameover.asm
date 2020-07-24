; asmsyntax=ca65

go_Ded:
    .byte " Game Over", $00
go_Win:
    .byte "OMG you won", $00
go_Start:
    .byte "  Press Start", $00

Init_GameWon:
    ldx #0
    stx TextEor
:
    lda go_Win, x
    sta TextBuffer, x
    beq @done
    inx
    cpx #18
    bne :-
@done:
    jsr TextPrepare
    jmp gameover_init

Init_GameOver:
    jsr TextClearStringBuffer

    ; load into the buffer
    ldx #0
    stx TextEor
:
    lda go_Ded, x
    sta TextBuffer, x
    beq @done
    inx
    cpx #18
    bne :-
@done:
    jsr TextPrepare


gameover_init:
    .Disable_Drawing
    .NMI_Disable

.repeat 8, i
    lda Pal_Tv+i
    sta PaletteBuffer+i
    sta PaletteBufferSprites+i
.endrepeat

    ;lda #' '
    ;jsr FillNametable0
    jsr ClearAttrTable0

    jsr ClearSprites

    lda #2
    jsr LoadChrData

    lda #$00
    sta AddressPointer0+0
    lda #$02
    sta AddressPointer0+1

    lda #12
    ldx #0
    jsr WriteTextBuffer

    jsr TextClearStringBuffer
    ldx #0
    stx TextEor
:
    lda go_Start, x
    sta TextBuffer, x
    beq @st_text_done
    inx
    cpx #18
    bne :-
@st_text_done:
    jsr TextPrepare

    lda #$20
    sta AddressPointer0+0
    lda #$03
    sta AddressPointer0+1

    lda #12
    ldx #$FF
    jsr WriteTextBuffer

    jsr WriteTvAttr

    lda #ScreenIDs::Tv
    ldx #$20
    jsr LoadScreen

    bit $2002
    ; Tiles for "Game Over"
    lda #$21
    sta $2006
    lda #$4B
    sta $2006

    ldx #$20
    ldy #12
:
    stx $2007
    inx
    dey
    bne :-

    ; Tiles for "Press Start"
    lda #$21
    sta $2006
    lda #$CA
    sta $2006

    ldx #$32
    ldy #12
:
    stx $2007
    inx
    dey
    bne :-

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
