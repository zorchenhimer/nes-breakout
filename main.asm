; asmsyntax=ca65

.feature leading_dot_in_identifiers
.feature underline_in_numbers

; Remove this line to disable debug code
DEBUG = 1

.importzp main_BOARD_DATA_WIDTH, main_BOARD_DATA_HEIGHT

.include "macros.asm"

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

.ifdef PAL
    FPS = 50
.else
    FPS = 60
.endif

CHILD_OFFSET_Y = 64 ; Is this a good spot for the child board?
CHILD_OFFSET_X = 80
CHILD_BOARD_HEIGHT = 6
CHILD_BOARD_WIDTH = 12

; Button Constants
BUTTON_A        = 1 << 7
BUTTON_B        = 1 << 6
BUTTON_SELECT   = 1 << 5
BUTTON_START    = 1 << 4
BUTTON_UP       = 1 << 3
BUTTON_DOWN     = 1 << 2
BUTTON_LEFT     = 1 << 1
BUTTON_RIGHT    = 1 << 0

; Scene chunk types
CHUNK_RLE = 1 << 5
CHUNK_RAW = 2 << 5
CHUNK_ADDR = 3 << 5
CHUNK_SPR = 4 << 5
CHUNK_DONE = 0 ; no more chunks

.enum InitIDs
    Title
    Game
    Credits
    LevelSelect
    GameOver
    ;ScreenTest
    GameWon
.endenum

.enum SceneIDs
    Intro
.endenum

.enum ChrData
    Credits
    Game
    Title
    Hex
    Game2
    LevelSelect
    Tv
    TvLower
.endenum

; Each command might take more than one frame to
; perform all its actions.  The commands should be
; implemented in a way that they can be executed
; across multiple frames in the NMI.  They should
; also have the ability to run outside of the NMI
; if the PPU has been turned off in a previous
; command.
.enum SceneCmd

    EOD = 0

    ; Turn off screen and draw a full screen Is
    ; followed by the page ID that contains the data
    ; and the address of the start data.
    DrawFullScene

    ; Wait a given number of seconds.
    WaitSeconds

    ; Wait a given number of frames.
    WaitFrames

    ; Takes no arguments.  If set, pressing START
    ; will skip to the next scmd_GotoInit command.
    SetSkippable
    SetUnskippable

    ; Draw null terminated text
    ; Arguments: [start PPU address] [text] $00
    DrawText

    ; Turn off the PPU and enable commands to draw
    ; to the screen outside of NMI
    TurnOffPPU

    ; Turn the PPU back on and disable drawing
    ; outside of the NMI.  This command should
    ; probably end in a WaitForNMI call.
    TurnOnPPU

    ; Fill the nametable with the next byte
    FillNametable

    ; Load CHR data onto the PPU
    LoadChr

    ; End a scene execution and jump to the given
    ; Init function.  Indexed with values from the
    ; data_Inits table
    GotoInit; = $FF

.endenum

.include "nes2header.inc"
nes2mapper 1
nes2prg 16 * 16 * 1024  ; 256k PRG
nes2chr 0
nes2chrram 1 * 8 * 1024 ; 8k CHR RAM
nes2wram 1 * 8 * 1024
nes2mirror 'V'
nes2tv 'N'
nes2end

.include "menu_ram.asm"

.segment "VECTORS"
    .word NMI_Instr
    .word RESET
    .word IRQ

.segment "ZEROPAGE"
AddressPointer0:    .res 2
AddressPointer1:    .res 2
AddressPointer2:    .res 2
AddressPointer3:    .res 2
AddressPointer4:    .res 2
AddressPointer5:    .res 2
AddressPointer6:    .res 2

Sleeping: .res 1

TmpW:   .res 1
TmpX:   .res 1
TmpY:   .res 1
TmpZ:   .res 1

IdxA:   .res 1
IdxB:   .res 1
IdxC:   .res 1
IdxD:   .res 1

PpuControl: .res 1

LastBank:      .res 1

IgnoreInput: .res 1

PaletteBuffer: .res 4*4
PaletteBufferSprites: .res 4*4

zp_BrickAddress: .res 2

FlipFlop: .res 1

btnX: .res 1
btnY: .res 1

.segment "RAMGLOBAL"

ChrWriteDest:       .res 1  ; $00 or $80. picks pattern table to write to.
ChrWriteTileCount:  .res 1

controller1:        .res 1
controller1_Old:    .res 1
controller2:        .res 1
controller2_Old:    .res 1

; Each level is a bit
CompletedLevels: .res 2

LastSpriteOffset: .res 1

sf_Skippable:   .res 1
sf_Frames:      .res 1
sf_Seconds:     .res 1
sf_PpuOn:       .res 1
sf_Scroll:      .res 1

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

.include "screen-data.i.idx"
.include "title.asm"
.include "level-select.asm"
.include "gameover.asm"
.include "screen-data.i"

.segment "PAGE03"
    .byte 3
.segment "PAGE04"
    .byte 4
.segment "PAGE05"
    .byte 5
.segment "PAGE06"
    .byte 6

anim_Matrix_Data14:
    .incbin "matrix14.chr"

anim_Matrix_Data7:
    .incbin "matrix7.chr"

.segment "PAGE07"
    .byte 7

WaveChrData:
    .incbin "waves.chr"

am_Waves_TileLayout_b:
    .repeat 4
        .repeat 8, i
            .repeat 4
            .byte OP_BG_INC, 8, $C0 + (i*8)
            .endrepeat
        .endrepeat
    .endrepeat

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

TitleData:
    .incbin "title.chr";, 0, (16 * 160) + (16 * 12) ; (bytes/tile * tile count)
;TitleData_Count = (* - TitleData) / 16
TitleData_Count = 0

.segment "PAGE13"
    .byte 13
;; Occupied by credit data

.segment "PAGE14"
    .byte 14

CreditsChrData:
    .incbin "credits.chr"
CreditsChrData_Count = 0    ; Zero so it wraps around

GameChrData:
    ; FIXME: generate the tile count for this stuff
    ; (and the lookup table below)
    .incbin "game.chr", 0, (16 * 16 * 6) ; bytes/tile * tiles/row * rows

GameChrData_Count = (* - GameChrData) / 16

HexTileData:
    .incbin "hex.chr", 0, (16 * 16)
HexTileData_Count = (* - HexTileData) / 16

LevelSelectTileData:
    .incbin "level-select.chr"
LevelSelectTileData_Count = 0

TvTileData:
    ;.incbin "title.chr", 0, (16 * 32) ; (bytes/tile * tile count)
    .incbin "tv.chr"
TvTileData_Count = ((* - TvTileData) / 16) & $FF

TvTileDataLower:
    .incbin "tv-lower.chr"
TvTileDataLower_Count = (* - TvTileDataLower) / 16

.out .sprintf("CreditsChrData_Count: %d", CreditsChrData_Count)
.out .sprintf("GameChrData_Count: %d", GameChrData_Count)
.out .sprintf("TitleData_Count: %d", TitleData_Count)
.out .sprintf("HexTileData_Count: %d", HexTileData_Count)
.out .sprintf("LevelSelectTileData_Count: %d", LevelSelectTileData_Count)

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

    lda SceneIDs::Intro
    jmp RunScene

    ;lda InitIDs::Title
    ;jmp JumpToInit

; Maybe change this to use a sleeping flag
; This can probably break if NMI goes long
WaitForNMI:
    lda NMI_Instr
    cmp #NMI_RTI
    bne :+

    .NMI_Set NMI_Bare

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

; TODO: Add an offset parameter?
LoadChrData:
    ldx $8000   ; Load the bank ID

    ; A holds index to Index_ChrData
    asl a
    asl a
    tay

    ; Load up data pointer
    lda Index_ChrData+0, y
    sta AddressPointer4+0
    lda Index_ChrData+1, y
    sta AddressPointer4+1

    ; Load up tile count
    lda Index_ChrData+2, y
    sta ChrWriteTileCount

    ; Load the destination pattern table, and mapper
    ; page that contains the CHR data.
    lda Index_ChrData+3, y
    and #$80
    beq :+
    lda #$10
    jmp :++
:
    lda #0
:
    sta AddressPointer5+1
    lda #0
    sta AddressPointer5+0
    ;sta ChrWriteDest

    ; Right half contains page of data
    lda Index_ChrData+3, y
    and #$0F
    jsr MMC1_Select_Page

    jsr WriteChrData

    ; Go back to the original page
    txa
    jsr MMC1_Select_Page

    rts

; Writes CHR data directly to RAM from ROM space
; Input:
;   AddressPointer4     source data location
;   AddressPointer5     destination address
;   ChrWriteTileCount   number of tiles
WriteChrData:
    bit $2002

    lda AddressPointer5+1
    sta $2006
    lda AddressPointer5+0
    sta $2006

@copyLoop:
    ldy #0
:   lda (AddressPointer4), y
    sta $2007
    iny
    cpy #16
    bne :-

    ; Increment pointer to next tile
    lda AddressPointer4
    clc
    adc #16
    sta AddressPointer4
    bcc :+
    inc AddressPointer4+1
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
    lda #0
    pha
    jmp utils_ClearAttrTable

ClearAttrTable1:
    bit $2002
    lda #$27
    sta $2006
    lda #0
    pha
    jmp utils_ClearAttrTable

ClearAttrTable2:
    bit $2002
    lda #$2B
    sta $2006
    lda #0
    pha
    jmp utils_ClearAttrTable

ClearAttrTable3:
    bit $2002
    lda #$2F
    sta $2006
    lda #0
    pha
    jmp utils_ClearAttrTable

FillAttrTable0:
    pha
    bit $2002
    lda #$23
    sta $2006
    jmp utils_ClearAttrTable

utils_ClearAttrTable:
    lda #$C0
    sta $2006
    ldx #8
    ;lda #$00
    pla
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

; Was a button pressed this frame?
ButtonPressedP1:
    sta btnX

    lda IgnoreInput
    beq :+
    dec IgnoreInput
    lda #0
    rts
:

    lda btnX
    and controller1
    sta btnY

    lda controller1_Old
    and btnX

    cmp btnY
    bne btnPress_stb

    ; no button change
    rts

ButtonPressedP2:
    sta btnX

    lda IgnoreInput
    beq :+
    dec IgnoreInput
    lda #0
    rts
:

    lda btnX
    and controller2
    sta btnY

    lda controller2_Old
    and btnX

    cmp btnY
    bne btnPress_stb

    ; no button change
    rts

btnPress_stb:
    ; button released
    lda btnY
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

Clear_NonGlobalZp:
    ldx #$80
    lda #0
:
    sta $00, x
    inx
    bne :-
    rts

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

; Jumps to an init in the init table. ID in A.  Use the
; InitIDs enum for IDs.
JumpToInit:
    ; multiply A by 5
    tay
    ldx data_Mult5, y

    ; grab the address pointer
    lda data_Inits+3, x
    sta AddressPointer0
    lda data_Inits+4, x
    sta AddressPointer0+1

    ; swap banks
    lda data_Inits+2, x
    jsr MMC1_Select_Page

    ; Reset stack
    ldx #$FF
    txs

    jmp (AddressPointer0)

WritePalettes:
    lda #PPU_CTRL_NMI
    sta $2000

    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

.repeat 32, i
    lda PaletteBuffer+i
    sta $2007
.endrepeat
    rts

; Binary value in A, ASCII Hex values output in TmpX and TmpY
BinToHex:
    sta TmpX
    lda #0
    sta TmpY

@tens:
    lda TmpX
    cmp #$10
    bcs @addtens
    jmp @done

@addtens:
    inc TmpY
    sec
    sbc #$10
    sta TmpX
    jmp @tens

@done:
    rts

data_Inits:
    ; Tile start ID, length, bank, init pointer
    .byte $00, 0, 2
        .word Init_Title
    .byte $00, 0, 0
        .word Init_Game
    .byte $00, 0, 13
        .word Init_Credits
    .byte $00, 0, 2
        .word Init_LevelSelect
    .byte $00, 0, 2
        .word Init_GameOver
    ;.byte $00, 0, 2
    ;    .word Init_ScreenTest
    .byte $00, 0, 2
        .word Init_GameWon

; TODO: find a way to auto-generate this table
Index_ChrData:
    ; Address of data start
    ; Tile count
    ; Dest table in bit 7, bank in bits 6-0

    .word CreditsChrData    ; Source address
    .byte CreditsChrData_Count
    .byte $FE   ; Destination pattern table & PRG bank

    .word GameChrData   ; Source address
    .byte GameChrData_Count    ; Tile count
    .byte $FE   ; Destination pattern table & PRG bank

    .word TitleData
    .byte TitleData_Count
    .byte $7C   ; Destination pattern table & PRG bank

    .word HexTileData
    .byte HexTileData_Count
    .byte $7E

    .word GameChrData   ; Source address
    .byte GameChrData_Count    ; Tile count
    .byte $7E   ; Destination pattern table & PRG bank

    .word LevelSelectTileData
    .byte LevelSelectTileData_Count
    .byte $7E

    .word TvTileData
    .byte TvTileData_Count
    .byte $7E

    .word TvTileDataLower
    .byte TvTileDataLower_Count
    .byte $FE

data_Mult3:
.repeat 10, i
    .byte (i * 3)
.endrepeat

data_Mult5:
.repeat 10, i
    .byte (i * 5)
.endrepeat

data_Mult12:
.repeat 10, i
    .byte (i * 12)
.endrepeat

data_Mult16_A:
.repeat 256, i
    .byte (i * 16) & $FF
.endrepeat

data_Mult16_B:
.repeat 256, i
    .byte (i * 16) >> 8
.endrepeat

.include "credits.asm"
.include "map_decode.asm"
.include "bg_anim.asm"
.include "screen-decode.asm"
.include "scene-engine.asm"
.include "scene-data.asm"
