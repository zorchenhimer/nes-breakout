; asmsyntax=ca65

CLEAR_TILE_ID   = 0
CR_T2_SPEED     = 8     ; color cycle speed (in frames) for the tier two names

Init_Credits:
    ; "Disable" NMI
    NMI_Disable

    ; Disable drawing BG and sprites
    lda #$00
    sta $2001

    jsr MMC1_Select_Horiz

    lda #$00
    jsr LoadChrData

    lda #<Credits_Palette
    sta AddressPointer3
    lda #>Credits_Palette
    sta AddressPointer3+1
    jsr WritePaletteData

    ;jsr LoadPalettes
    ;jsr WritePalettes

    lda #$00
    jsr FillNametable0
    lda #$00
    jsr FillNametable2

    jsr ClearAttrTable0
    jsr ClearAttrTable2

    jsr ClearSprites
    jsr WriteSprites

    lda #0
    sta cr_currentAttrOffset
    sta cr_AttrSecondWrite
    sta cr_AttrTmp
    sta cr_AttributeReady
    sta cr_UpdateReady
    ;sta cr_chunkCurrent
    sta cr_currentPPULine
    sta cr_scroll
    sta cr_tileBufferOffset
    sta AddressPointer2+1
    sta TmpZ

    lda #<credits_data_chunks
    sta AddressPointer1
    lda #>credits_data_chunks
    sta AddressPointer1+1

    lda #$23
    sta AddressPointer2

; Fill the screen with names
    lda #30
    sta TmpX
@loop:
    jsr Credits_LoadChunk
    jsr Credits_WriteBuffer
    dec TmpX
    bne @loop

    lda #CR_SCROLL_WAIT
    sta cr_scrollWait

    lda #32
    sta cr_nextChunkWait

    lda #$21
    sta cr_tier3Color
    lda #0
    sta cr_tier2Color
    lda #CR_T2_SPEED
    sta cr_t2Count

    NMI_Set Credits_NMI

    ;lda #$00
    ;sta $2000
    lda #%00011110
    sta $2001

    ; reset scroll
    bit $2002
    lda #$00
    sta $2005
    sta $2005

    lda #CR_TOP
    sta cr_scroll_table
    jmp Credits_Frame
    ;rts

Credits_WriteAttr:
    lda #0
    sta cr_AttributeReady

    lda AddressPointer2
    sta $2006
    lda AddressPointer2+1
    sta $2006

    ldx #8
    lda cr_AttributeByte
@loop:
    sta $2007
    dex
    bne @loop

    lda #0
    sta cr_AttributeByte

    lda AddressPointer2+1
    cmp #$F8
    beq :+
    rts

:   lda AddressPointer2
    cmp #$23
    bne @firstNT
    jmp @secondNT

@firstNT:
    lda #$23
    sta AddressPointer2
    jmp @done

@secondNT:
    lda #$2B
    sta AddressPointer2

@done:
    rts

; Write the cr_TileBuffer to the PPU
Credits_WriteBuffer:
    lda #0
    sta cr_UpdateReady
    lda cr_currentPPULine
    cmp #30
    bcc @noWrap
    lda #0
    sta cr_currentPPULine

@noWrap:
    tax
    inc cr_currentPPULine

    lda PPU_RowStartLookup_High, x
    sta $2006
    lda PPU_RowStartLookup_Low, x
    sta $2006
    ldx #0
    ldy #64
@loop:
    lda cr_TileBuffer, x
    sta $2007
    inx
    dey
    bne @loop

    ; increment and rollover the count
    ;inc cr_chunkCurrent
    ;lda cr_chunkCurrent
    ;cmp #Credits_NameCount
    ;bcc @noRollover

    ;lda #0
    ;sta cr_chunkCurrent

;@noRollover:

    ;dec cr_nextAttrWait
    ;bne @noAttr
    ;lda #3
    ;sta cr_nextAttrWait
    bit cr_AttributeReady
    bvc @noAttr

    jmp Credits_WriteAttr

@noAttr:
    rts

; Two byte increment
cr_Decode_Opcode_IncAddr:
    ;lda AddressPointer1
    clc
    adc AddressPointer1
    sta AddressPointer1

    lda AddressPointer1+1
    adc #0
    sta AddressPointer1+1
    rts

cr_OPCodes:
    .word cr_op_EndOfChunk
    .word cr_op_ClearRow
    .word cr_op_IncrementByte
    .word cr_op_RunLength
    .word cr_op_ByteList
    .word cr_op_Attr
    .word cr_op_Name
    .word cr_op_EndOfData

; Call this with a JSR
Credits_LoadChunk:
    lda #CR_UPDATE_TILE
    sta cr_UpdateReady

    lda #0
    sta cr_tileBufferOffset

    ;lda cr_chunkCurrent

    asl a
    tax

    ;lda credits_data_chunks, x
    ;sta cr_chunkAddress

    ;lda credits_data_chunks+1, x
    ;sta cr_chunkAddress+1

    ;jmp cr_Decode_Opcode

; Before this is called, figure out the credits_data_chunk_## address
cr_Decode_Opcode:
    ldy #0
    lda (AddressPointer1), y
    asl a
    tax

    ; load address of op code subroutine
    lda cr_OPCodes, x
    sta AddressPointer0
    lda cr_OPCodes+1, x
    sta AddressPointer0+1

    ; jump to it
    jmp (AddressPointer0)

cr_ClearRow:
    ldx cr_tileBufferOffset
    ldy #32
    lda #CLEAR_TILE_ID
@loop:
    sta cr_TileBuffer, x
    inx
    dey
    bne @loop

    lda cr_tileBufferOffset
    clc
    adc #32
    sta cr_tileBufferOffset

    lda #1
    jmp cr_Decode_Opcode_IncAddr

; Add 32 bytes of Spaces to the tile buffer
cr_op_ClearRow:
    jsr cr_ClearRow
    jmp cr_Decode_Opcode

; Start at the given byte and increment N times
cr_op_IncrementByte:
    ; increment past OP code
    lda #1
    jsr cr_Decode_Opcode_IncAddr
    ldy #0

    ; number of bytes to write
    lda (AddressPointer1), y
    tax

    lda #1
    jsr cr_Decode_Opcode_IncAddr

    ; Data to start at
    lda (AddressPointer1), y
    sta cr_tmpByte

    ; move length from X to Y
    txa
    tay

    ldx cr_tileBufferOffset
@loop:
    lda cr_tmpByte
    sta cr_TileBuffer, x
    inc cr_tmpByte
    inx
    dey
    bne @loop

    ; store the buffer offset
    stx cr_tileBufferOffset

    lda #1
    jsr cr_Decode_Opcode_IncAddr
    jmp cr_Decode_Opcode

; Repeat a byte N times
cr_op_RunLength:
    ; increment past OP code
    lda #1
    jsr cr_Decode_Opcode_IncAddr
    ldy #0

    ; number of bytes to write
    lda (AddressPointer1), y
    sta cr_chunkLength
    ;inc cr_chunkLength
    lda #1
    jsr cr_Decode_Opcode_IncAddr

    ; data byte
    lda (AddressPointer1), y

    ldy cr_chunkLength
    ldx cr_tileBufferOffset
@loop:
    sta cr_TileBuffer, x
    inx
    dey
    bne @loop

    ; Update buffer offset
    lda cr_tileBufferOffset
    clc
    adc cr_chunkLength
    sta cr_tileBufferOffset

    lda #1
    jsr cr_Decode_Opcode_IncAddr
    jmp cr_Decode_Opcode

; Dump a list of bytes to the buffer
cr_op_ByteList:
    jsr cr_ByteList
    jmp cr_Decode_Opcode

cr_ByteList:
    lda #1
    jsr cr_Decode_Opcode_IncAddr
    ldx cr_tileBufferOffset
    ldy #0
    sty cr_tmpByte
@loop:
    lda (AddressPointer1), y
    beq @done
    sta cr_TileBuffer, x
    inx
    inc cr_tmpByte
    iny
    jmp @loop

@done:
    lda cr_tmpByte
    clc
    adc cr_tileBufferOffset
    sta cr_tileBufferOffset

    inc cr_tmpByte
    lda cr_tmpByte
    jsr cr_Decode_Opcode_IncAddr
    rts

cr_op_Attr:
    ; don't increment if coming from cr_op_Name
    bit cr_AttrTmp
    bmi :+
    lda #1
    jsr cr_Decode_Opcode_IncAddr

:   lda cr_AttrSecondWrite
    bne @secondWrite

    lda cr_currentAttrOffset
    cmp #7
    beq @lastRow

    lda cr_AttrTmp
    bmi @notChunkA

    ldy #0
    lda (AddressPointer1), y
    jmp @notChunkADone

@notChunkA:
    and #$0F

@notChunkADone:
    sta cr_AttributeByte

    lda #0
    sta cr_AttrTmp

    inc cr_AttrSecondWrite
    jmp cr_op_EndOfChunk

@secondWrite:

    lda cr_AttrTmp
    bmi @notChunkB
    lda (AddressPointer1), y
    jmp @notChunkBDone

@notChunkB:
    and #$0F

@notChunkBDone:
    asl A
    asl A
    asl A
    asl A

    ora cr_AttributeByte
    sta cr_AttributeByte

    ldx cr_currentAttrOffset
    inc cr_currentAttrOffset

    lda PPU_AttrLookup_Low, x
    sta AddressPointer2+1

    lda #$FF
    sta cr_AttributeReady
    lda #0
    sta cr_AttrSecondWrite
    sta cr_AttrTmp
    jmp cr_op_EndOfChunk

@lastRow:
    lda cr_AttrTmp
    bmi @notChunkC

    ldy #0
    lda (AddressPointer1), y
    jmp @notChunkCDone

@notChunkC:
    and #$0F

; Last row stuff
@notChunkCDone:
    sta cr_AttributeByte

    asl A
    asl A
    asl A
    asl A

    ora cr_AttributeByte
    sta cr_AttributeByte

    ldx cr_currentAttrOffset
    lda PPU_AttrLookup_Low, x
    sta AddressPointer2+1

    ; wrap to the next nametable
    lda #0
    sta cr_currentAttrOffset
    sta cr_AttrTmp

    lda #$FF
    sta cr_AttributeReady

cr_op_EndOfChunk:
    lda #1
    jmp cr_Decode_Opcode_IncAddr

cr_op_EndOfData:
    lda #<credits_data_chunks
    sta AddressPointer1
    lda #>credits_data_chunks
    sta AddressPointer1+1
    jmp Credits_LoadChunk

cr_op_Name:
    ; Clear the row, prefix spaces, suffix spaces, attribute, name data
    jsr cr_ClearRow

    ; Metadata byte.  bits 7-6 are attribute, rest are length.
    ldy #0
    lda (AddressPointer1), y
    and #$3F
    sta cr_nameLength

    lda (AddressPointer1), y
    and #$C0    ; get Attribute bits

    ; Rotate bits 7-6 to bits 1-0
    clc
    rol a
    rol a
    rol a
    sta cr_AttrTmp

    ; fill the nibble
    asl a
    asl a
    ora cr_AttrTmp
    ora #$80
    sta cr_AttrTmp

    ; write attribute stuff
    jsr cr_op_Attr

    ; Length
    lda cr_nameLength
    lsr a   ; divide by two

    sta TmpY
    lda #16
    sec
    sbc TmpY    ; the amount of padding

    sta cr_loopCounter
    ldy #0
    lda #CR_PADDING
    ldx cr_tileBufferOffset

:   sta cr_TileBuffer, x
    inx
    iny
    cpy cr_loopCounter
    bne :-

    ldy #0
    lda cr_nameLength
    sta cr_loopCounter
    sta TmpY

    ; Loop through data for the given length
:   lda (AddressPointer1), y
    sta cr_TileBuffer, x
    iny
    inx
    dec TmpY
    bne :-

    ; suffix padding
    lda #CR_PADDING
:   sta cr_TileBuffer, x
    inx
    cpx #64     ; 32 is end of row, 64 is end of second row.
    bne :-

    lda cr_nameLength
    jmp cr_Decode_Opcode_IncAddr

    ; padding to fix the dissassembly in the debugger
    .byte $EA, $EA

cr_colors_T2:
    .byte $00

cr_colors_T3:
    .byte $00

cr_TierColors:
    lda cr_t2Count
    bne @t3check

    lda #CR_T2_SPEED
    sta cr_t2Count

; Tier two color
    inc cr_tier2Color
    ldx cr_tier2Color
    cpx #6
    bne :+
    ldx #0
    stx cr_tier2Color

:
    ;lda Credits_Tier2, x
    ;sta PaletteRAM+26

@t3check:
    dec cr_t2Count

    lda TmpZ
    bne :+
    lda #1
    sta TmpZ
    rts

:   lda #0
    sta TmpZ

; Tier three color
    inc cr_tier3Color
    lda cr_tier3Color
    cmp #$2C
    bne :+
    lda #$21
    sta cr_tier3Color
:
    ;lda cr_tier3Color
    ;sta PaletteRAM+22

    rts

Credits_Frame:
    jsr cr_TierColors

; This is for the actual rom. CRDEBUG is defined in the
; credits dev makefile.
;.ifndef CRDEBUG
;    lda #BUTTON_START
;    jsr ButtonPressedP1
;    beq @nobutton
;
;    lda #STATES::GS_TITLE
;    sta current_gamestate
;    inc gamestate_changed
;@nobutton:
;.endif

    lda cr_scrollWait
    bne @notYet

    lda #CR_SCROLL_SPEED
    sta cr_scrollWait

    inc cr_scroll

    ; Do we need to draw the next name?
    dec cr_nextChunkWait
    bne @noChunk
    lda #16
    sta cr_nextChunkWait
    jsr Credits_LoadChunk

@noChunk:
    lda cr_scroll
    cmp #$F0
    bcs @rollOver
    jmp @nextFrame

@notYet:
    dec cr_scrollWait

@nextFrame:
    jsr WaitForNMI
    jmp Credits_Frame

@rollOver:
    lda #0
    sta cr_scroll
    lda cr_scroll_table
    cmp #CR_TOP
    beq @gotoBottom
    lda #CR_TOP
    sta cr_scroll_table
    jmp @nextFrame

@gotoBottom:
    lda #CR_BOTTOM
    sta cr_scroll_table
    jmp @nextFrame

Credits_NMI:
    ; TODO: update color cycle
    ;jsr WritePalettes
    bit $2002

    ; Tier 2 colors
    lda #$3F
    sta $2006
    lda #$05
    sta $2006

    ldx cr_tier2Color
    lda Credits_Tier2, x
    sta $2007

    ; Tier 3 colors
    lda #$3F
    sta $2006
    lda #$09
    sta $2006

    lda cr_tier3Color
    sta $2007

    jsr WriteSprites

    bit cr_UpdateReady
    bpl @noUpdate
    jsr Credits_WriteBuffer

@noUpdate:
    dec Sleeping

    ; Scroll
    bit $2002
    ; X
    lda #0
    sta $2005
    ; Y
    lda cr_scroll
    sta $2005
    ; Name table
    lda cr_scroll_table
    sta $2000
    ;jmp NMI_Finished
    rti

; start of row addresses - 30 total rows
PPU_RowStartLookup_High:
    .byte $20, $20, $20, $20, $21, $21, $21, $21
    .byte $22, $22, $22, $22, $23, $23, $23
    .byte $28, $28, $28, $28, $29, $29, $29, $29
    .byte $2A, $2A, $2A, $2A, $2B, $2B, $2B

PPU_RowStartLookup_Low:
    .byte $00, $40, $80, $C0, $00, $40, $80, $C0
    .byte $00, $40, $80, $C0, $00, $40, $80
    .byte $00, $40, $80, $C0, $00, $40, $80, $C0
    .byte $00, $40, $80, $C0, $00, $40, $80

; low byte of attribute table - 8 total rows
PPU_AttrLookup_Low:
    .byte $C0, $C8, $D0, $D8, $E0, $E8, $F0, $F8

Credits_Palette:
    .byte $0F,$30,$13,$23, $0F,$05,$15,$0F, $0F,$0A,$1A,$0F, $0F,$11,$21,$0F
    .byte $0F,$30,$13,$0F, $0F,$05,$15,$0F, $0F,$0A,$1A,$0F, $0F,$11,$21,$0F

Credits_Tier2:
    .byte $03, $13, $23, $33, $23, $13