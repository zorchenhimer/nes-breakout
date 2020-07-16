; asmsyntax=ca65

.import cr_data_groups
.importzp CR_GROUP_COUNT

.include "credits_ram.asm"

CLEAR_TILE_ID   = 0
CR_T2_SPEED     = 8     ; color cycle speed (in frames) for the tier two names

CR_INIT_NAME_COUNT = 11
CR_START_GROUP = 1
CR_FIRST_SCREEN_SIZE = 8 ; number of names on the first screen
                         ; that will not need a scroll.

CR_SCROLL_SPEED = 3     ; frames to wait for the next scroll update
CR_SCROLL_WAIT  = 120   ; frames to wait to start scrolling

CR_TOP      = %10011000
CR_BOTTOM   = %10011010

CR_UPDATE_TILE  = %10000000
CR_UPDATE_ATTR  = %01000000

CR_PADDING      = $20
CR_CHUNK_TIMER  = 16 ; frames between chunk loading (for cr_nextChunkWait)
CR_NEXT_GROUP_PAUSE = 60 ; time to pause between groups (n * CR_SCROLL_SPEED) frames

CR_SCROLL_TO_PAUSE = 48 ; lines to scroll before pausing.

Init_Credits:
    ; "Disable" NMI
    .NMI_Disable

    ; Disable drawing BG and sprites
    lda #$00
    sta $2001

    jsr MMC1_Select_Horiz

    lda #<Credits_Palette
    sta AddressPointer3
    lda #>Credits_Palette
    sta AddressPointer3+1
    jsr WritePaletteData

    lda #$00
    jsr LoadChrData

    ;jsr LoadPalettes
    ;jsr WritePalettes

    ;lda #$00
    ;jsr FillNametable0
    ;lda #$00
    ;jsr FillNametable2

    ;jsr ClearAttrTable0
    ;jsr ClearAttrTable2

    jsr ClearSprites
    jsr WriteSprites

    jsr Clear_CreditRam

    lda #$23
    sta AddressPointer2

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

    ;lda #$00
    ;sta $2000

    ; reset scroll
    ;bit $2002
    ;lda #$00
    ;sta $2005
    ;sta $2005

    lda #CR_TOP
    sta cr_scroll_table

    lda #CR_START_GROUP
    sta cr_currentGroup
    jmp credits_LoadGroup
    ;jmp Credits_Frame
    ;rts

; Loads up a name, and changes the
; group if necessary.
credits_LoadData:
    jsr credits_LoadName
    beq :++

    inc cr_currentGroup
    lda cr_currentGroup
    cmp #CR_GROUP_COUNT
    bcc :+
    lda #1
    sta cr_currentGroup
:
    jsr credits_LoadGroup
    jsr credits_LoadName
:
    rts

credits_LoadNextGroup:
    inc cr_currentGroup
    lda cr_currentGroup
    cmp #CR_GROUP_COUNT
    bcc :+
    lda #1
    sta cr_currentGroup
:   ; Fall-through to credits_LoadGroup

; Group index in A
; Switches to the next group, clears the screen, draws
; the header, and draws the initial screen for the group.
credits_LoadGroup:
    pha
    .NMI_Disable

    jsr WaitForNMI
    pla
    asl a
    tax

    ; Load pointer to group data
    lda cr_data_groups, x
    sta AddressPointer1
    lda cr_data_groups+1, x
    sta AddressPointer1+1
    lda #0
    sta cr_nextGroup

    ; Load pointer to the group's init code
    lda credits_GroupInits, x
    sta AddressPointer0
    lda credits_GroupInits+1, x
    sta AddressPointer0+1

    ; Wait for the next NMI to avoid artifacts
    .NMI_Set NMI_Bare
    jsr WaitForNMI

    ; Disable drawing BG and sprites
    lda #$00
    sta $2001

    ; Clear the screen
    lda #$00
    jsr FillNametable0
    lda #$00
    jsr FillNametable2

    jsr ClearAttrTable0
    jsr ClearAttrTable2

    ; Reset the scroll stuff
    lda #CR_TOP
    sta cr_scroll_table

    lda #CR_SCROLL_TO_PAUSE
    sta cr_scrollToPause

    lda #0
    sta cr_scroll
    sta cr_AttributeReady
    sta cr_AttributeByte
    sta cr_AttrSecondWrite

    lda #1
    sta cr_nextChunkWait

    ; Draw the header (this might move later)
    jsr credits_DrawTwitchHeader

    lda #$23
    sta AddressPointer2

    ; Jump to the group's init code
    jmp (AddressPointer0)

credits_GroupInits:
    .word credits_group_attrib
    .word credits_group_1year
    .word credits_group_9months
    .word credits_group_6months
    .word credits_group_3months
    .word credits_group_1month

credits_GroupLabels:
    .word :+
    .word :++
    .word :+++
    .word :++++
    .word :+++++
    .word :++++++

:   .byte "what", $00
:   .byte "One Year", $00
:   .byte "Nine Months", $00
:   .byte "Six Months", $00
:   .byte "Three Months", $00
:   .byte "One Month", $00


; Draws the group's names to the screen, up to the
; max names per screen.
credits_group_drawNames:
    lda #6
    sta cr_currentPPULine

    lda #CR_INIT_NAME_COUNT
    sta TmpX

    lda #3
    sta cr_currentAttrOffset

    ; Number of names initially
    ; written to the screen.
    lda #0
    sta TmpZ

    lda #CR_NEXT_GROUP_PAUSE
    sta cr_nextGroupPaused

@nameLoop:
    jsr credits_LoadName
    bne @loopEnd

    jsr credits_WriteBuffer
    inc TmpZ
    dec TmpX
    bne @nameLoop

@loopEnd:

    lda #CR_SCROLL_WAIT
    sta cr_scrollWait

    lda TmpZ
    cmp #CR_FIRST_SCREEN_SIZE
    ; if TmpZ > CR_FIRST_SCREEN_SIZE, scroll the screen
    ; else, draw new screen instead of scrolling.
    bcs :+

    ; Pause for the same amount of time as the multi-screen groups
    ; by not pausing before a non-existent scroll
    lda #CR_SCROLL_SPEED
    sta cr_scrollWait
    lda #$80
    sta cr_singleScreen
    jmp :++
:
    lda #$00
    sta cr_singleScreen
:
    jsr credits_clearTileBuffer
    jmp Credits_Frame

; Label ID in A
; PPU address should already be set before
; calling this.
credits_DrawGroupLabel:
    asl a
    tax
    lda credits_GroupLabels, x
    sta AddressPointer0
    lda credits_GroupLabels+1, x
    sta AddressPointer0+1

    ldy #0
:   lda (AddressPointer0), y
    beq :+
    sta $2007
    iny
    jmp :-
:
    rts

credits_group_attrib:
    rts

credits_group_1year:

    lda #$21
    sta $2006
    lda #$0C
    sta $2006

    lda #1
    jsr credits_DrawGroupLabel
    jmp credits_group_drawNames

; Clear tile buffer
credits_clearTileBuffer:
    ldy #64
    ldx #0
    lda #0
:   sta cr_TileBuffer, x
    inx
    dey
    bne :-
    rts

credits_group_9months:
    lda #$21
    sta $2006
    lda #$0B
    sta $2006

    lda #2
    jsr credits_DrawGroupLabel

    jmp credits_group_drawNames

credits_group_6months:
    lda #$21
    sta $2006
    lda #$0C
    sta $2006

    lda #3
    jsr credits_DrawGroupLabel
    jmp credits_group_drawNames

credits_group_3months:
    lda #$21
    sta $2006
    lda #$0A
    sta $2006

    lda #4
    jsr credits_DrawGroupLabel
    jmp credits_group_drawNames

credits_group_1month:
    lda #$21
    sta $2006
    lda #$0C
    sta $2006

    lda #5
    jsr credits_DrawGroupLabel
    jmp credits_group_drawNames

credits_DrawTwitchHeader:
    ; three rows down, seven columns in
    lda #$20
    sta $2006
    lda #$47
    sta $2006

    ; increment byte loop
    ldy #$10
    ldx #3
:
    sty $2007
    iny
    dex
    bne :-

    ; increment byte loop
    ldy #$02
    ldx #7
:
    sty $2007
    iny
    dex
    bne :-

    ; second row
    lda #$20
    sta $2006
    lda #$67
    sta $2006

    ; increment byte loop
    ldy #$13
    ldx #3
:
    sty $2007
    iny
    dex
    bne :-

    ; increment byte loop
    ldy #$80
    ldx #15
:
    sty $2007
    iny
    dex
    bne :-

    lda #$20
    sta $2006
    lda #$87
    sta $2006

    ; increment byte loop
    ldy #$16
    ldx #3
:
    sty $2007
    iny
    dex
    bne :-

    ; increment byte loop
    ldy #$90
    ldx #15
:
    sty $2007
    iny
    dex
    bne :-


    rts

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
credits_WriteBuffer:
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

    bit cr_AttributeReady
    bvc @noAttr

    jmp Credits_WriteAttr

@noAttr:
    rts

; Two byte increment.  Increment by value in A.
cr_Decode_Opcode_IncAddr:
    clc
    adc AddressPointer1
    sta AddressPointer1

    lda AddressPointer1+1
    adc #0
    sta AddressPointer1+1
    rts

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
    ;jmp cr_Decode_Opcode
    rts

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
    ;jmp cr_Decode_Opcode
    rts

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

credits_LoadAttrib:
    ldx #0  ; offset in the buffer

    ; type and length of data
    ldy #0
@attribLoop:
    lda (AddressPointer1), y
    beq @done
    bmi @name   ; TODO: do different things for label and name

    sta cr_nameLength   ; length of label, not name, but w/e

    iny
:   lda (AddressPointer1), y
    sta cr_attribBuffer, x
    iny
    dec cr_nameLength
    bne :-

    jmp @attribLoop

@name:
    and #$7F
    sta cr_nameLength   ; it's a name this time.

    iny
:   lda (AddressPointer1), y
    sta cr_attribBuffer, x
    iny
    dec cr_nameLength
    bne :-
    jmp @attribLoop

@done:
    rts

; Load the current name into RAM
credits_LoadName:
    lda #CR_UPDATE_TILE
    sta cr_UpdateReady

    ; Metadata byte.  bits 7-6 are attribute, rest are length.
    ldy #0
    lda (AddressPointer1), y
    bne :+
    lda #1
    sta cr_nextGroup
    rts
:
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
    jsr cr_Decode_Opcode_IncAddr
    lda #0
    rts

    ; padding to fix the dissassembly in the debugger
    ;.byte $EA, $EA
    nop
    nop

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
    bne @t3check
    ldx #0
    stx cr_tier2Color

@t3check:
    dec cr_t2Count

    lda cr_frameOdd
    bne :+
    lda #1
    sta cr_frameOdd
    rts

:   lda #0
    sta cr_frameOdd

; Tier three color
    inc cr_tier3Color
    lda cr_tier3Color
    cmp #$2C
    bne :+
    lda #$21
    sta cr_tier3Color
:
    rts

Credits_FrameBare:
    jsr WaitForNMI
    jmp Credits_FrameBare

Credits_Frame:
    .NMI_Set Credits_NMI

    jsr ReadControllers

    lda #BUTTON_START
    jsr ButtonPressedP1
    beq :+
    lda #0
    jmp JumpToInit
:

    jsr cr_TierColors

    bit cr_singleScreen
    bpl @multiScreen
    ; single screen, pause for a few frames before loading the next group
    lda cr_scrollWait
    beq :+
    dec cr_scrollWait
    jmp @nextFrame
:
    lda #CR_SCROLL_SPEED
    sta cr_scrollWait

    dec cr_nextGroupPaused  ; should be set when loading a group.
    bne @nextFrame

    ; timer hit zero, load next group
    jmp credits_LoadNextGroup

@multiScreen:
    lda cr_scrollWait
    beq :+
    ; don't scroll yet
    dec cr_scrollWait
    jmp @nextFrame
:

    ; scroll a line, reload scroll wait for next time
    lda #CR_SCROLL_SPEED
    sta cr_scrollWait

    lda cr_nextGroup
    beq @nextName
    ; cr_nextGroup isn't zero, we've hit the end.

    ; scroll to the point where we should pause.
    lda cr_scrollToPause
    beq :+
    dec cr_scrollToPause
    jsr credits_IncScroll
    jmp @nextFrame
:   ; finished scrolling to the end
    ; wait to go to next group.
    dec cr_nextGroupPaused
    bne @nextFrame

    ; counter hit zero, load next group
    jmp credits_LoadNextGroup

@nextName:
    ; not paused, continue scrolling
    jsr credits_IncScroll

    ; Do we need to draw the next name?
    dec cr_nextChunkWait
    bne @nextFrame

    ; it's time to draw a new chunk
    lda #CR_CHUNK_TIMER
    sta cr_nextChunkWait

    jsr credits_LoadName
    beq :+
    ; clear the buffer if we've hit the end
    jsr credits_clearTileBuffer
:

@nextFrame:
    jsr WaitForNMI
    jmp Credits_Frame

Credits_NMI:
    lda #%00011110
    sta $2001

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
    jsr credits_WriteBuffer

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
    rti

; Increment cr_scroll and check for rollover
credits_IncScroll:
    inc cr_scroll

    lda cr_scroll
    cmp #$F0
    bcs :+
    rts ; no rollover
:
    ; Handle scroll roll over
    lda #0
    sta cr_scroll
    lda cr_scroll_table
    cmp #CR_TOP
    beq @gotoBottom
    lda #CR_TOP
    sta cr_scroll_table
    rts

@gotoBottom:
    lda #CR_BOTTOM
    sta cr_scroll_table
    rts

Clear_CreditRam:
    lda #0
    ldx #0
:
    sta CREDIT_RAM_START, x
    inx
    cpx #CREDIT_RAM_SIZE
    bne :-
    rts

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
