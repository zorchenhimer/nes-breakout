; asmsyntax=ca65

; Load screen data to the PPU

Init_ScreenTest:
    .NMI_Disable
    .Disable_Drawing

    lda #<screen_Hood
    sta AddressPointer0
    lda #>screen_Hood
    sta AddressPointer0+1

    jsr LoadScreen

    .Update_PpuControl PPU_CTRL_NMI
    .Update_PpuMask 0

Frame_ScreenTest:
    .NMI_Set NMI_ScreenTest

    jmp Frame_ScreenTest

NMI_ScreenTest:
    .Update_PpuControl PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN
    .Update_PpuMask PPU_MASK_ON | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND
    rti

; Expects pointer to screen data in AddressPointer0
LoadScreen:
    lda #0
    ; this is used as a two byte counter, not a pointer
    ; stop drawing when count hits 960 ($03C0)
    sta AddressPointer1
    sta AddressPointer1+1

    bit $2002
    lda #$20
    sta $2006
    lda #$00
    sta $2006

@loop:
    ; AddressPointer0 should always point to the
    ; start of a chunk
    ldy #0
    lda (AddressPointer0), y
    sta TmpZ
    bpl :+
    jsr screen_DecodeRAW
    jmp @next
:
    jsr screen_DecodeRLE

@next:
    iny
    ; Get address of next chunk
    tya
    clc
    adc AddressPointer0
    sta AddressPointer0

    lda AddressPointer0+1
    adc #0
    sta AddressPointer0+1

    ; Add previous chunk length to counter
    lda TmpZ
    and #$7F
    clc
    adc AddressPointer1
    sta AddressPointer1

    lda AddressPointer1+1
    adc #0
    sta AddressPointer1+1

    cmp #3
    bcc @loop

    lda AddressPointer1
    cmp #$C0
    bcc @loop

    rts

screen_DecodeRLE:
    tax
    iny

    and #$01
    bne @even
    ; odd
    lda (AddressPointer0), y
    sta $2007
    dex
    jmp @loop

@even:
    lda (AddressPointer0), y
@loop:
    sta $2007
    sta $2007
    dex
    bne @loop
    rts

screen_DecodeRAW:
    ; Remove top bit
    and #$7F
    tax

@loop:
    iny
    lda (AddressPointer0), y
    sta $2007
    dex
    bne @loop
    rts
