; asmsyntax=ca65

; Load screen data to the PPU

ScreenTest_Palette:
    .byte $0F, $0F, $00, $10
    .byte $0F, $00, $20, $10

; Quadrants of the attribute data for better readability
ST_BOTL = %0001_0000
ST_BOTR = %0100_0000
ST_TOPL = %0000_0001
ST_TOPR = %0000_0100

Init_ScreenTest:
    .NMI_Disable
    .Disable_Drawing

    jsr ClearSprites
    jsr WriteSprites
    jsr ClearAttrTable0
    jsr ClearAttrTable1

    lda #<screen_Hood
    sta AddressPointer0
    lda #>screen_Hood
    sta AddressPointer0+1

    ldx #$20
    jsr LoadScreen

    lda #<screen_TvStatic
    sta AddressPointer0
    lda #>screen_TvStatic
    sta AddressPointer0+1

    ldx #$24
    jsr LoadScreen

    ldx #0
:
    lda ScreenTest_Palette, x
    sta PaletteBuffer, x
    sta PaletteBufferSprites, x
    inx
    cpx #8
    bne :-

    jsr WritePalettes

    ; Copy sprites from ROM to RAM
    ldx #0
:
    lda screen_Sprites, x
    sta Sprites, x
    inx
    bne :-

    jsr WriteTvAttr

    .Update_PpuControl PPU_CTRL_NMI
    .Update_PpuMask 0

Frame_ScreenTest:
    .NMI_Set NMI_ScreenTest

    lda #10
    ldx #0
    ldy #PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN | PPU_CTRL_SP_PATTERN | 1

    jsr WaitForSpriteZero
    ;sta $2005
    ;stx $2005
    sty $2000

    ldy #PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN | PPU_CTRL_SP_PATTERN | 0

    ldx #0
:
    .repeat 18
    nop
    .endrepeat
    dex
    bne :-

    ldx #70
:
    dex
    bne :-

    sty $2000

    jsr WaitForNMI
    jmp Frame_ScreenTest

NMI_ScreenTest:
    jsr WriteSprites

    .Update_PpuControl PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN | PPU_CTRL_SP_PATTERN
    .Update_PpuMask PPU_MASK_ON | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND

    lda #0
    sta $2005
    sta $2005
    dec Sleeping
    rti

; Fill the second nametable with static
FillStatic:
    lda #$20
    sta $2006
    lda #$C8
    sta $2006

    .repeat 5
    ldx #$1A
    sta 2007
    inx
    sta 2007
    inx
    sta 2007
    inx
    sta 2007
    inx
    sta 2007
    .endrepeat
    rts

WriteTvAttr:
    ; 23CA
    lda #$23
    sta $2006
    lda #$CA
    sta $2006

    lda #ST_BOTL | ST_BOTR
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$23
    sta $2006
    lda #$D2
    sta $2006

    lda #ST_BOTL | ST_BOTR | ST_TOPL | ST_TOPR
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$23
    sta $2006
    lda #$DA
    sta $2006

    lda #ST_BOTL | ST_BOTR | ST_TOPL | ST_TOPR
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$23
    sta $2006
    lda #$E2
    sta $2006

    lda #ST_TOPL | ST_TOPR
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    rts

; Expects pointer to screen data in AddressPointer0 and
; the high byte of the Nametable address in X
LoadScreen:
    lda #0
    ; this is used as a two byte counter, not a pointer
    ; stop drawing when count hits 960 ($03C0)
    sta AddressPointer1
    sta AddressPointer1+1

    bit $2002
    ;lda #$20
    stx $2006
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
    beq @even
    ; odd
    lda (AddressPointer0), y
    sta $2007
    dex
    bne @loop
    rts ; there was only one byte of data.  just return

@even:
    lda (AddressPointer0), y
@loop:
    sta $2007
    sta $2007
    dex
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
