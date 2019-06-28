; asmsyntax=ca65

.include "nes2header.inc"
nes2mapper 1
nes2prg 16 * 16 * 1024  ; 256k PRG
nes2chr 0
nes2chrram 1 * 8 * 1024 ; 8k CHR RAM
nes2wram 1 * 8 * 1024
nes2mirror 'V'
nes2tv 'N'
nes2end

.segment "VECTORS"
    .word NMI_Instr
    .word RESET
    .word IRQ

.segment "ZEROPAGE"
AddressPointer0:    .res 2
AddressPointer1:    .res 2
AddressPointer2:    .res 2
AddressPointer3:    .res 2

TmpX:   .res 1
TmpY:   .res 1
TmpZ:   .res 1

.segment "BSS"
ChrWriteDest:       .res 1  ; $00 or $80. picks pattern table to write to.
ChrWriteTileCount:  .res 1

.include "credits_ram.asm"

.segment "NMIRAM"
NMI_Instr:      .res 1
NMI_Pointer:    .res 2

NMI_RTI = $40
NMI_JMP = $4C

.segment "OAM"
Sprites: .res 256

.segment "WRAM"

.segment "PAGE00"
.segment "PAGE01"
.segment "PAGE02"
.segment "PAGE03"
.segment "PAGE04"
.segment "PAGE05"
.segment "PAGE06"
.segment "PAGE07"
.segment "PAGE08"
.segment "PAGE09"
.segment "PAGE10"
.segment "PAGE11"
.segment "PAGE12"
.segment "PAGE13"
.include "credits_data.i"

.segment "PAGE14"

CreditsChrData:
    .incbin "credits.chr"

.segment "PAGE_FIXED"
IRQ:
    rti

RESET:
    sei         ; Disable IRQs
    cld         ; Disable decimal mode

    ldx #$40
    stx $4017   ; Disable APU frame IRQ

    ldx #$FF
    txs         ; Setup new stack

    inx         ; Now X = 0

    stx $2000   ; disable NMI
    stx $2001   ; disable rendering
    stx $4010   ; disable DMC IRQs

:   ; First wait for VBlank to make sure PPU is ready.
    bit $2002   ; test this bit with ACC
    bpl :- ; Branch on result plus

:   ; Clear RAM
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x

    inx
    bne :-  ; loop if != 0

    ; set NMI to just RTI
    lda #NMI_RTI
    sta NMI_Instr

:   ; Second wait for vblank.  PPU is ready after this
    bit $2002
    bpl :-

    lda #$88
    sta $2000

    ;jsr MMC1_Init
    jmp Credits_Init

Forever:
    jsr WaitForNMI
    jmp Forever

; Maybe change this to use a sleeping flag
; This can probably break if NMI goes long
WaitForNMI:
:   bit $2002
    bpl :-
    rts

MMC1_Init:
    ; Set flag
    jsr MMC1_Select_Vert

    ; select CHR 0
    lda #%00000000

    sta $A000
    lsr a
    sta $A000
    lsr a
    sta $A000
    lsr a
    sta $A000
    lsr a
    sta $A000
    rts

MMC1_Select_Vert:
    ; control stuff
    ; vertical mirroring, switchable $8000, fixed $C000, chr 8k
    ; %0000 1110
    lda #%00001110
    jmp MMC1_Setup

MMC1_Select_Horiz:
    lda #%00001111

MMC1_Setup:
    sta $8000
    lsr a
    sta $8000
    lsr a
    sta $8000
    lsr a
    sta $8000
    lsr a
    sta $8000
    rts

MMC1_Select_Page:
    sta $E000
    lsr a
    sta $E000
    lsr a
    sta $E000
    lsr a
    sta $E000
    lsr a
    sta $E000
    rts

WriteSprites:
    bit $2002
    lda #$00
    sta $2003
    lda #$02
    sta $4014
    rts

; Write all eight palettes to the PPU directly from ROM space
; Uses AddressPointer3 as input
WritePaletteData:
    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    ldy #0
:
    lda (AddressPointer3), y
    sta $2007
    iny
    cpy #16
    bne :-

    rts

; Writes CHR data directly to RAM from ROM space
; Input:
;   AddressPointer3     source data location
;   ChrWriteDest        destination pattern table
;   ChrWriteTileCount   number of tiles
WriteChrData:
    bit $2002

    bit ChrWriteDest
    bmi @bottomTable
    lda #$00
    sta $2006
    sta $2006
    jmp @copyLoop

@bottomTable:
    lda #$10
    sta $2006
    lda #$00
    sta $2006

@copyLoop:
    ldy #0
:   lda (AddressPointer3), y
    sta $2007
    iny
    cpy #16
    bne :-

    ; Increment pointer to next tile
    lda AddressPointer3
    clc
    adc #16
    sta AddressPointer3
    bcc :+
    inc AddressPointer3+1
:
    dec ChrWriteTileCount
    bne @copyLoop

    rts

FillNametable0:
    sta TmpX

    bit $2002
    lda #$20
    sta $2006
    jmp utils_FillNametable

FillNametable1:
    sta TmpX

    bit $2002
    lda #$24
    sta $2006
    jmp utils_FillNametable

FillNametable2:
    sta TmpX

    bit $2002
    lda #$28
    sta $2006
    jmp utils_FillNametable

FillNametable3:
    sta TmpX

    bit $2002
    lda #$2C
    sta $2006
    jmp utils_FillNametable

utils_FillNametable:
    lda #00
    sta $2006

    ldx #30
    lda TmpX
@loop2:
.repeat 32
    sta $2007
.endrepeat
    dex
    bne @loop2
    rts

ClearAttrTable0:
    bit $2002
    lda #$23
    sta $2006
    jmp utils_ClearAttrTable

ClearAttrTable1:
    bit $2002
    lda #$27
    sta $2006
    jmp utils_ClearAttrTable

ClearAttrTable2:
    bit $2002
    lda #$2B
    sta $2006
    jmp utils_ClearAttrTable

ClearAttrTable3:
    bit $2002
    lda #$2F
    sta $2006
    jmp utils_ClearAttrTable

utils_ClearAttrTable:
    lda #$C0
    sta $2006
    ldx #8
    lda #$00
@loop:
.repeat 8
    sta $2007
.endrepeat
    dex
    bne @loop
    rts

.include "credits.asm"

