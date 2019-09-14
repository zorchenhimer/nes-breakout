; asmsyntax=ca65

.importzp main_BOARD_DATA_WIDTH, main_BOARD_DATA_HEIGHT

.ifdef ROW26
    BOARD_WIDTH = 26
    BOARD_HEIGHT = 12
    BOARD_OFFSET_Y = 32
    BOARD_OFFSET_X = 24
.else
; I've only got map data at a width of 24 for now
    BOARD_WIDTH = 24
    BOARD_HEIGHT = 12
    BOARD_OFFSET_Y = 32
    BOARD_OFFSET_X = 32
.endif

CHILD_OFFSET_Y = 64 ; Is this a good spot for the child board?
CHILD_OFFSET_X = 80
CHILD_BOARD_HEIGHT = 6
CHILD_BOARD_WIDTH = 12

.macro NMI_Disable
    lda #NMI_RTI
    sta NMI_Instr
.endmacro

.macro NMI_Set addr
    lda #NMI_JMP
    sta NMI_Instr

    lda #<addr
    sta NMI_Pointer
    lda #>addr
    sta NMI_Pointer+1
.endmacro

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

Sleeping: .res 1

TmpW:   .res 1
TmpX:   .res 1
TmpY:   .res 1
TmpZ:   .res 1

IdxA:   .res 1
IdxB:   .res 1
IdxC:   .res 1

PpuControl: .res 1

; number of frames to wait between
; animation frames
waves_AnimWait: .res 1
; which pattern table?
waves_AnimOdd: .res 1
; row to send to the ppu
waves_currentRow: .res 1
waves_currentFrame: .res 1

waves_ChrDest:  .res 2  ; CHR address to start writing
waves_ChrSrc:   .res 2  ; the start of an 8 tile row

LastBank:      .res 1

IgnoreInput: .res 1

.segment "RAMGLOBAL"

ChrWriteDest:       .res 1  ; $00 or $80. picks pattern table to write to.
ChrWriteTileCount:  .res 1

controller1:        .res 1
controller1_Old:    .res 1
controller2:        .res 1
controller2_Old:    .res 1


.segment "NMIRAM"
NMI_Instr:      .res 1
NMI_Pointer:    .res 2

NMI_RTI = $40
NMI_JMP = $4C

.segment "OAM"
Sprites: .res 256

.segment "WRAM"

;; Just the mini map data for bricks that have been interacted with


.segment "PAGE00"
    .byte 0
;; Game Code
.include "game.asm"

.segment "PAGE01"
    .byte 1
;.include "map_data.i"

.assert BOARD_WIDTH = main_BOARD_DATA_WIDTH, error, "Board data width does not match code!"
.assert BOARD_HEIGHT = main_BOARD_DATA_HEIGHT, error, "Board data height does not match code!"

.out .sprintf("Board Width: %d", BOARD_WIDTH)
.out .sprintf("Board Height: %d", BOARD_HEIGHT)

.segment "PAGE02"
    .byte 2
.include "title.asm"

.segment "PAGE03"
    .byte 3
.segment "PAGE04"
    .byte 4
.segment "PAGE05"
    .byte 5
.segment "PAGE06"
    .byte 6
.segment "PAGE07"
    .byte 7

WaveChrData:
    .incbin "waves.chr"

.segment "PAGE08"
    .byte 8
.segment "PAGE09"
    .byte 9
.segment "PAGE10"
    .byte 10

.segment "PAGE11"
    .byte 11
;; Minimap data

.segment "PAGE12"
    .byte 12
;; Overworld map Data

.segment "PAGE13"
    .byte 13
;; Occupied by credit data

.segment "PAGE14"
    .byte 14

CreditsChrData:
    .incbin "credits.chr"
GameChrData:
    ; FIXME: generate the tile count for this stuff
    ; (and the lookup table below)
    .incbin "game.chr", 0, (16 * 16)
TitleData:
    ; 128 tiles. includes a character set
    .incbin "title.chr", 0, 2048

HexTileData:
    .incbin "hex.chr", 0, (16 * 16)

.segment "PAGE_FIXED"
    .byte 15
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

    jsr MMC1_Init

    lda #<Init_Title
    sta AddressPointer0
    lda #>Init_Title
    sta AddressPointer0+1
    lda #2
    jmp LongJump

    ;lda #2
    ;jsr MMC1_Select_Page

    ;jmp Init_Title
    ;jmp Init_Game
    ;jmp Init_Credits
    ;jmp NtSwapTest

Forever:
    jsr WaitForNMI
    jmp Forever

; Maybe change this to use a sleeping flag
; This can probably break if NMI goes long
WaitForNMI:
    lda NMI_Instr
    cmp #NMI_RTI
    bne :+

    NMI_Set NMI_Bare

:   bit Sleeping
    bpl :-
    lda #0
    sta Sleeping
    rts

WaitForSpriteZero:
; Wait for VBlank to end
:   bit $2002
    bvs :-

; Wait for sprite zero hit
:   bit $2002
    bvc :-
    rts

NMI_Bare:
    pha
    lda #$FF
    sta Sleeping
    pla
    rti

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

; Take a bank in A, and pointer in AddressPointer0.
; Swap to the bank in A, and jump to the pointer.
LongJump:
    jsr MMC1_Select_Page
    jmp (AddressPointer0)

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

ClearSprites:
; clear sprites
    lda #$FF
    ldx #0
:
    sta Sprites, x
    inx
    bne :-
    rts

NtSwapTest:
    ; "Disable" NMI
    lda #NMI_JMP
    sta NMI_Instr

    lda #<NMI_Bare
    sta NMI_Pointer+0
    lda #>NMI_Bare
    sta NMI_Pointer+1

    ; Disable drawing BG and sprites
    lda #$00
    sta $2001

    jsr MMC1_Select_Vert

    bit $2002

    ; NT00
    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda #0
    ldx #240
:
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    dex
    bne :-

    ; attr table
    ldx #64
:
    sta $2007
    dex
    bne :-

    lda #$20
    tax
    sta $2006
    sta $2006

    lda #$11
:
    sta $2007
    dex
    bne :-

    ; NT01
    lda #$24
    sta $2006
    lda #$00
    sta $2006
    lda #$FF
    ldx #240
:
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    dex
    bne :-

    ; attr table
    ldx #64
    lda #$00
:
    sta $2007
    dex
    bne :-


    lda #$20
    sta $2006
    lda #$00
    sta $2006
    lda #$FF
    sta $2007

    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    lda #$0F
    sta $2007
    lda #$11
    sta $2007
    lda #$14
    sta $2007
    lda #$1B
    sta $2007


    ; sprite zero
    lda #1
    sta Sprites+0
    sta Sprites+3

    lda #$FF
    sta Sprites+1
    lda #0
    sta Sprites+2

    jsr WriteSprites

    lda #14
    jsr MMC1_Select_Page

    lda #<GameChrData
    sta AddressPointer3
    lda #>GameChrData
    sta AddressPointer3+1
    lda #$00
    sta ChrWriteTileCount
    lda #$00
    sta ChrWriteDest
    jsr WriteChrData

    lda #00
    jsr MMC1_Select_Page

    lda #%00011110
    sta $2001

    lda #$80
    sta $2000

    ; reset scroll
    bit $2002
    lda #$00
    sta $2005
    sta $2005

NtSwapFrame:
    jsr WaitForNMI

    lda #$80
    sta $2000

    ; Wait for SP Zero

    ; wait for vblank to end
:   bit $2002
    bvs :-

; wait for sprite zero hit
:
    bit $2002
    bvc :-

; wait loop
    ldx #255
:
    nop
    dex
    bne :-

    lda #$81
    sta $2000

    jmp NtSwapFrame

LoadChrData:
    ldx $8000   ; Load the bank ID

    ; A holds index to Index_ChrData
    asl a
    asl a
    tay

    ; Load up data pointer
    lda Index_ChrData+0, y
    sta AddressPointer3+0
    lda Index_ChrData+1, y
    sta AddressPointer3+1

    ; Load up tile count
    lda Index_ChrData+2, y
    sta ChrWriteTileCount

    ; Load the destination pattern table, and mapper
    ; page that contains the CHR data.
    lda Index_ChrData+3, y
    sta ChrWriteDest

    ; Right half contains page of data
    and #$0F
    jsr MMC1_Select_Page

    jsr WriteChrData

    ; Go back to the original page
    txa
    jsr MMC1_Select_Page

    rts

; TODO: find a way to auto-generate this table
Index_ChrData:
    ; Address of data start
    ; Tile count
    ; Dest table in bit 7, bank in bits 6-0

    .word CreditsChrData    ; Source address
    .byte $00   ; Tile count
    .byte $FE   ; Destination pattern table & PRG bank

    .word GameChrData   ; Source address
    .byte 16    ; Tile count
    .byte $FE   ; Destination pattern table & PRG bank

    .word TitleData
    .byte 144   ; Tile Count
    .byte $FE   ; Destination pattern table & PRG bank

    .word HexTileData
    .byte 16
    .byte $7E

    .word GameChrData   ; Source address
    .byte 16    ; Tile count
    .byte $7E   ; Destination pattern table & PRG bank

; Button Constants
BUTTON_A        = 1 << 7
BUTTON_B        = 1 << 6
BUTTON_SELECT   = 1 << 5
BUTTON_START    = 1 << 4
BUTTON_UP       = 1 << 3
BUTTON_DOWN     = 1 << 2
BUTTON_LEFT     = 1 << 1
BUTTON_RIGHT    = 1 << 0

; Was a button pressed this frame?
ButtonPressedP1:
    sta TmpX

    lda IgnoreInput
    beq :+
    dec IgnoreInput
    lda #0
    rts
:

    lda TmpX
    and controller1
    sta TmpY

    lda controller1_Old
    and TmpX

    cmp TmpY
    bne btnPress_stb

    ; no button change
    rts

ButtonPressedP2:
    sta TmpX

    lda IgnoreInput
    beq :+
    dec IgnoreInput
    lda #0
    rts
:

    lda TmpX
    and controller2
    sta TmpY

    lda controller2_Old
    and TmpX

    cmp TmpY
    bne btnPress_stb

    ; no button change
    rts

btnPress_stb:
    ; button released
    lda TmpY
    bne btnPress_stc
    rts

btnPress_stc:
    ; button pressed
    lda #1
    rts

; Player input
ReadControllers:
    lda controller1
    sta controller1_Old

    lda controller2
    sta controller2_Old

    ; Freeze input
    lda #1
    sta $4016
    lda #0
    sta $4016

    LDX #$08
@player1:
    lda $4016
    lsr A           ; Bit0 -> Carry
    rol controller1 ; Bit0 <- Carry
    dex
    bne @player1

    ldx #$08
@player2:
    lda $4017
    lsr A           ; Bit0 -> Carry
    rol controller2 ; Bit0 <- Carry
    dex
    bne @player2
    rts

IncPointer0:
    inc AddressPointer0
    bne :+
    inc AddressPointer0+1
:   rts

; Clears ram from $0400 to $07FC
Clear_NonGlobalRam:
    lda #$00
    sta AddressPointer0
    lda #$04
    sta AddressPointer0+1
    jsr clr_ram

    inc AddressPointer0+1   ; $0500
    jsr clr_ram
    inc AddressPointer0+1   ; $0600
    jsr clr_ram

    inc AddressPointer0+1
    ldy #$FC
:
    .repeat 3
    sta (AddressPointer0), y
    dey
    .endrepeat
    bne :-

    sta (AddressPointer0), y

    rts

; clears one page
clr_ram:
    ldy #0
    lda #0
:   sta (AddressPointer0), y
    iny
    bne :-
    rts

Clear_ExtendedRam:
    ldx #2
    ldy #$00
    ldx #$20

    lda #$60
    sta AddressPointer0+1
    lda #$00
    sta AddressPointer0

@loop:
    .repeat 32
    sta (AddressPointer0), y
    iny
    .endrepeat
    bne @loop

    inc AddressPointer0+1
    dex
    bne @loop

    rts

; Jumps to an init in the init table
JumpToInit:
    ; multiply A by 5
    tay
    ldx data_Mult5, y

    ; grab the address pointer
    lda data_Inits+3, x
    sta AddressPointer0
    lda data_Inits+4, x
    sta AddressPointer0+1

    ; grab the bank
    lda data_Inits+2, x

    ; do a long jump
    jmp LongJump

; Draws the wave's tile IDs on the background
Wave_DrawBackground:
    ; row counter 0 - 7
    ; col counter 0 - 7
    ; repeat per row 0-3
    bit $2002

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda #0
    sta IdxC    ; number of frames, vertically

    lda #8
    sta TmpZ    ; Number of rows in the frame

@topFrame:  ; start of a row of frames
    lda #0
    sta IdxB    ; row of frame
@topLoop:
    ; calculate the value of the first tile
    ; index in the frame's row.
    lda IdxB
    asl a
    asl a
    asl a
    clc
    adc #$C0
    sta TmpX

    lda #4
    sta IdxA
@screenRowLoop:
    ldx TmpX
    ; Draw a row of the animation frame
    .repeat 8, i
    stx $2007
    inx
    .endrepeat

    dec IdxA
    bne @screenRowLoop

    inc IdxB
    lda IdxB
    cmp TmpZ
    bcc @topLoop

    inc IdxC
    lda IdxC
    cmp #3
    bcc @topFrame

    lda TmpZ
    cmp #6
    bne :+
    rts
:
    lda #6
    sta TmpZ
    jmp @topFrame

; Frame ID in A
; Bit 7 determines pattern table
;   0 - top
;   1 - bottom
Waves_LoadFrame:
    bit $2002

    sta IdxA
    bit IdxA
    bmi :+
    lda #$0C
    jmp :++
:
    lda #$1C
:
    sta $2006
    lda #$00
    sta $2006

    lda IdxA
    asl a
    tax

    lda data_WaveFrames, x
    sta AddressPointer0
    lda data_WaveFrames+1, x
    sta AddressPointer0+1

    lda $8000
    pha

    lda #7
    jsr MMC1_Select_Page

    ldx #4  ; page loop
    ;sta TmpX    ; page loop
    ldy #0
@loop:
    lda (AddressPointer0), y
    sta $2007
    iny
    bne @loop

    inc AddressPointer0+1
    dex
    bne @loop

    pla
    jsr MMC1_Select_Page
    rts

; sets up addresses and variables for waves_UnrolledRow
waves_PrepChrWrite:
    lda PpuControl
    sta $2000
    ; Write the destination CHR address
    lda waves_AnimOdd   ; top or bottom pattern table
    beq @bottom
    lda #$0C
    sta waves_ChrDest+1
    jmp @rowOffset

@bottom:
    lda #$1C
    sta waves_ChrDest+1

@rowOffset:
    ;lda #$00
    ;sta waves_ChrDest+0

    lda waves_currentRow
    asl a
    tax

    ; add the offset for the row start
    lda data_WaveRowOffsets, x
    sta waves_ChrDest

    lda data_WaveRowOffsets+1, x
    clc
    adc waves_ChrDest+1
    sta waves_ChrDest+1

    ; Figure out source address start

    lda waves_currentFrame
    asl a
    tay

    lda data_WaveFrames, y
    sta waves_ChrSrc
    lda data_WaveFrames+1, y
    sta waves_ChrSrc+1

    ;lda #<WaveChrData
    ;sta waves_ChrSrc
    ;lda #>WaveChrData
    ;sta waves_ChrSrc+1

    lda waves_currentRow
    asl a
    tax

    ; Add the offset for the row start
    lda data_WaveRowOffsets, x
    clc
    adc waves_ChrSrc
    sta waves_ChrSrc

    lda data_WaveRowOffsets+1, x
    adc waves_ChrSrc+1
    sta waves_ChrSrc+1

    inc waves_currentRow
    lda waves_currentRow
    cmp #8
    bcc :+
    lda #0
    sta waves_currentRow
:
    rts

waves_WriteRow:
    lda $8000
    pha

    lda #7
    jsr MMC1_Select_Page

    bit $2000
    lda waves_ChrDest+1
    sta $2006
    lda waves_ChrDest+0
    sta $2006

    ldy #0

.repeat 8, t   ; tile loop
    .repeat 16, i ; bytes in the tile
    ;lda WaveChrData + (t * 16) + i
    lda (waves_ChrSrc), y
    sta $2007
    iny
    .endrepeat
.endrepeat

    pla
    jsr MMC1_Select_Page

    rts

data_WaveFrames:
    .repeat 15, i
    .word WaveChrData + (1024 * i)
    .endrepeat

data_WaveRowOffsets:
    .repeat 8, i
    .word ((16 * 8) * i)
    ;.out .sprintf("> %d", ((16 * 8) * i))
    .endrepeat

data_Inits:
    ; Tile start ID, length, bank, init pointer
    .byte $00, 0, 2
        .word Init_Title
    .byte $00, 0, 0
        .word Init_Game
    .byte $00, 0, 13
        .word Init_Credits

data_Mult5:
.repeat 10, i
    .byte (i * 5)
.endrepeat

data_Mult12:
.repeat 10, i
    .byte (i * 12)
.endrepeat

.include "credits.asm"
.include "map_decode.asm"
