; asmsyntax=ca65

.macro .NMI_Disable
    lda #NMI_RTI
    sta NMI_Instr
.endmacro

.macro .NMI_Set addr
    lda #NMI_JMP
    sta NMI_Instr

    lda #<addr
    sta NMI_Pointer
    lda #>addr
    sta NMI_Pointer+1
.endmacro

.macro .Disable_Drawing
    lda #$00
    sta $2001
.endmacro

PPU_MASK_EMPH_RED = %0010_0000
PPU_MASK_EMPH_GREEN = %0100_0000
PPU_MASK_EMPH_BLUE = %1000_0000
PPU_MASK_SHOWSPRITES = %0001_0000
PPU_MASK_SHOWBACKGROUND = %0000_1000
PPU_MASK_LEFTSPRITES = %0000_0100
PPU_MASK_LEFTBACKGROUND = %0000_0010
PPU_MASK_GREYSCALE = %0000_0001

PPU_MASK_ON = PPU_MASK_SHOWSPRITES | PPU_MASK_SHOWBACKGROUND | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND

.macro .Update_PpuMask args
    lda #args
    sta $2001
.endmacro

.macro .SetScroll _ScrollX, _ScrollY
    .ifblank _ScrollY
        lda #_ScrollX
        sta $2005
        sta $2005
    .else
        bit $2002
        lda #_ScrollX
        sta $2005
        lda #_ScrollY
        sta $2005
    .endif
.endmacro

.macro .WriteSprites
    bit $2002
    lda #$00
    sta $2003
    lda #$02
    sta $4014
.endmacro
