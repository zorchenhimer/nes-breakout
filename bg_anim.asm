; asmsyntax=ca65

.pushseg
.segment "ZPGAME" : zeropage

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

.segment "RAMGLOBAL"
; One row of the background animation
ChrRamCacheRow: .res 128

; current frame for each animation
bg_frames: .res 8
; number of total frames for each animation
bg_frameCount: .res 8

.popseg

; OP, write count, start value
OP_BG_INC = $01

; op, write count, value
OP_BG_RLE = $02

; op, length, list of data
OP_BG_BYT = $04

Animation_Meta_Waves:
    .byte 1
    .byte 0

    .word am_Waves_AnimIndex
    .word am_Waves_TileLayout

am_Waves_AnimIndex:
    .repeat 15, i
    .word WaveChrData + (1024 * i)
    .endrepeat

am_Waves_TileLayout:
    .repeat 4
        .repeat 8, i
            .repeat 4
            .byte OP_BG_INC, 8, $C0 + (i*8)
            .endrepeat
        .endrepeat
    .endrepeat

; Entire bg animation, made up of smaller animations.
Animation_Meta_Matrix:
    .byte 2 ; number of animations
    .byte 1 ; write direction for tiles

    ; Animation frame lookup table
    .word am_Matrix_AnimIndex

    ; Nametable tile data
    .word am_Matrix_TileLayout

am_Matrix_AnimIndex:
    .word am_Matrix_Col14
    .word am_Matrix_Col7

am_Matrix_Col14:
    .byte 14 | $C0  ; number of frames AND'd with bitplanes
    .byte 14    ; number of tiles per frame
    .byte $C0   ; start tile ID (dest)
    .byte $06   ; Bank ID

    .word anim_Matrix_Data14Lookup

anim_Matrix_Data14Lookup:
    .repeat 14, i
    .word anim_Matrix_Data14 + ((14 * 16) * i)
    .endrepeat

am_Matrix_Col7:
    .byte 14 | $C0  ; number of frames AND'd with bitplanes
    .byte 7     ; number of tiles per frame
    .byte $C0   ; start tile ID (dest)
    .byte $06   ; Bank ID

    .word anim_Matrix_Data14Lookup

anim_Matrix_Data7Lookup:
    .repeat 14, i
    .word anim_Matrix_Data7 + ((14 * 16) * i)
    .endrepeat

am_Matrix_TileLayout:
    ; tile data. RLE, ByteList, RLE_Inc.

; Animation_Meta_Matrix end

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

waves_CacheRow:
    jsr waves_PrepChrWrite

    lda NMI_Pointer
    pha
    lda NMI_Pointer+1
    pha

    .NMI_Disable

    lda $8000
    pha

    lda #7
    jsr MMC1_Select_Page

    ldx #128
    ldy #0
@loop:
    lda (waves_ChrSrc), y
    sta ChrRamCacheRow, y
    iny
    dex
    bne @loop

    pla
    jsr MMC1_Select_Page

    lda #NMI_JMP
    sta NMI_Instr

    pla
    sta NMI_Pointer+1
    pla
    sta NMI_Pointer
    rts

; Prepare a row of 8 tiles (128 bytes) from the
; background animation to send with waves_UnrolledRow
waves_PrepChrWrite:
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

waves_WriteCachedRow:
    lda PpuControl
    sta $2000

    bit $2000
    lda waves_ChrDest+1
    sta $2006
    lda waves_ChrDest+0
    sta $2006

.repeat 8, t   ; tile loop
    .repeat 16, i ; bytes in the tile
    ;lda WaveChrData + (t * 16) + i
    lda ChrRamCacheRow + (t * 16) + i
    sta $2007
    .endrepeat
.endrepeat
    rts

; Write a single row of background animation to CHR
; RAM.  One row is 8 tiles (128 bytes).  The row data
; needs to be prepared during the previous frame draw
; before calling this.
waves_WriteRow:
    lda PpuControl
    sta $2000

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
