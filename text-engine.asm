; asmsyntax=ca65

.segment "PAGE_FIXED"

    ; Redefining ASCII code points
    ;.include "font.map.asm"
    ;.charmap ' ', $FF   ; The only one that can't really be auto-generated

    SPACE_WIDTH = 5

; Clear a set of 16 tiles, starting at the address in AddressPointer0
; X holds values for first bit plane
; A holds values for second bit plane
ClearTileRow:
    pha
    bit $2002
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006
    pla

    .repeat 16
        .repeat 8
        stx $2007
        .endrepeat
        .repeat 8
        sta $2007
        .endrepeat
    .endrepeat
    rts

WriteBufferUnrolled:
    bit $2002
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    .repeat 16, B
        .repeat 8, C
        lda ChrBuffer + ((B*8) + C)
        sta $2007
        .endrepeat

        lda #0
        .repeat 8
        sta $2007
        .endrepeat
    .endrepeat

    lda #$00
    sta ChrBufferReady
    rts

;Text_ResetTiles_8:
;    bit $2002
;    lda AddressPointer0+1
;    sta $2006
;    lda AddressPointer0+0
;    sta $2006
;
;    lda #0
;    .repeat 8*16
;    sta $2007
;    .endrepeat
;    rts
;
;Text_ResetTiles_15:
;    bit $2002
;    lda AddressPointer0+1
;    sta $2006
;    lda AddressPointer0+0
;    sta $2006
;
;    lda #0
;    .repeat 15*16
;    sta $2007
;    .endrepeat
;    rts

; A has count
; X has the BG palette value thing in it
WriteTextBuffer_LevelSelect_15:
    bit $2002
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ldy #0
    .repeat 17, i
    lda ChrBuffer+(i*8)+0
    sta $2007

    lda ChrBuffer+(i*8)+1
    sta $2007

    lda ChrBuffer+(i*8)+2
    sta $2007

    lda ChrBuffer+(i*8)+3
    sta $2007

    lda ChrBuffer+(i*8)+4
    sta $2007

    lda ChrBuffer+(i*8)+5
    sta $2007

    lda ChrBuffer+(i*8)+6
    sta $2007

    lda ChrBuffer+(i*8)+7
    sta $2007

    ; Second plane
    .repeat 8
    sty $2007
    .endrepeat
    .endrepeat

    lda #$00
    sta ChrBufferReady
    rts

WriteTextBuffer_LevelSelect_7:
    bit $2002
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ldy #0
    .repeat 8, i
    lda ChrBuffer+((i+8)*8)+0
    sta $2007

    lda ChrBuffer+((i+8)*8)+1
    sta $2007

    lda ChrBuffer+((i+8)*8)+2
    sta $2007

    lda ChrBuffer+((i+8)*8)+3
    sta $2007

    lda ChrBuffer+((i+8)*8)+4
    sta $2007

    lda ChrBuffer+((i+8)*8)+5
    sta $2007

    lda ChrBuffer+((i+8)*8)+6
    sta $2007

    lda ChrBuffer+((i+8)*8)+7
    sta $2007

    ; Second plane
    .repeat 8
    sty $2007
    .endrepeat
    .endrepeat

    lda #$00
    sta ChrBufferReady
    rts

WriteTextBuffer_LevelSelect_8:
    bit $2002
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ldy #0
    .repeat 8, i
    lda ChrBuffer+(i*8)+0
    sta $2007

    lda ChrBuffer+(i*8)+1
    sta $2007

    lda ChrBuffer+(i*8)+2
    sta $2007

    lda ChrBuffer+(i*8)+3
    sta $2007

    lda ChrBuffer+(i*8)+4
    sta $2007

    lda ChrBuffer+(i*8)+5
    sta $2007

    lda ChrBuffer+(i*8)+6
    sta $2007

    lda ChrBuffer+(i*8)+7
    sta $2007

    ; Second plane
    .repeat 8
    sty $2007
    .endrepeat
    .endrepeat

    lda #$00
    sta ChrBufferReady
    rts

; A has count
; X has the BG palette value thing in it
WriteTextBuffer_LevelSelect:
    sta ChrCount
    bit $2002
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ldy #0
    ldx #0
@loop:
    lda ChrBuffer, x
    sta $2007

    lda ChrBuffer+1, x
    sta $2007

    lda ChrBuffer+2, x
    sta $2007

    lda ChrBuffer+3, x
    sta $2007

    lda ChrBuffer+4, x
    sta $2007

    lda ChrBuffer+5, x
    sta $2007

    lda ChrBuffer+6, x
    sta $2007

    lda ChrBuffer+7, x
    sta $2007

    ; Second plane
    .repeat 8
    sty $2007
    .endrepeat

    txa
    clc
    adc #8
    tax

    ;cpx #0
    cpx #(18*8)
    bcs @done
    beq @done

    dec ChrCount
    lda ChrCount
    bne @loop
@done:

    lda #$00
    sta ChrBufferReady
    sta TextEor
    rts

; A has count
; X has the BG palette value thing in it
PreparePartialTextWrite:
    sta ChrCount
    txa
    sta BgTextPal
    lda #0
    sta TextIdx
    lda #$FF
    sta TextEor
    rts

; Similar to WriteTextBuffer, but only
; writes a few tiles. (one for now)
WritePartialTextBuffer:
    bit $2002
    lda AddressPointer6+1
    sta $2006
    lda AddressPointer6+0
    sta $2006

    ldx TextIdx

    .repeat 8,i
    lda ChrBuffer+i, x
    eor TextEor
    sta $2007
    .endrepeat

    txa
    clc
    adc #8
    sta TextIdx

    ; Second plane
    lda BgTextPal
    .repeat 8
    sta $2007
    .endrepeat

    clc
    lda #16
    adc AddressPointer6+0
    sta AddressPointer6+0
    bcc :+
    inc AddressPointer6+1
:
    lda #0
    sta $2005
    sta $2005
    rts

; A has count
; X has the BG palette value thing in it
WriteTextBuffer:
    sta ChrCount
    txa
    pha
    bit $2002
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ldy #0
    ldx #0
@loop:
    lda ChrBuffer, x
    eor TextEor
    sta $2007

    lda ChrBuffer+1, x
    eor TextEor
    sta $2007

    lda ChrBuffer+2, x
    eor TextEor
    sta $2007

    lda ChrBuffer+3, x
    eor TextEor
    sta $2007

    lda ChrBuffer+4, x
    eor TextEor
    sta $2007

    lda ChrBuffer+5, x
    eor TextEor
    sta $2007

    lda ChrBuffer+6, x
    eor TextEor
    sta $2007

    lda ChrBuffer+7, x
    eor TextEor
    sta $2007

    ; Second plane
    pla
    pha
    .repeat 8
    sta $2007
    .endrepeat

    txa
    clc
    adc #8
    tax

    ;cpx #0
    cpx #(18*8)
    bcs @done
    beq @done

    dec ChrCount
    lda ChrCount
    bne @loop
@done:
    pla

    lda #$00
    sta ChrBufferReady
    sta TextEor
    rts

TextClearBuffer:
    lda #0
    ldx #0
:
    .repeat 8
    sta ChrBuffer, x
    inx
    .endrepeat
    cpx #(21 * 8)
    bne :-
    rts

TextClearStringBuffer:
    lda #0
    sta TextBuffer
    ldx #1
:
    sta TextBuffer, x
    inx
    sta TextBuffer, x
    inx
    cpx #21
    bne :-

    rts

txt_InsertSpace_v3:
    lda #SPACE_WIDTH
    sta ChrWidth
    clc
    adc ChrOffset
    sec
    sbc #8
    cmp #0
    bpl @overflow

    ; Underflow
    lda #SPACE_WIDTH
    clc
    adc ChrOffset
    sta ChrOffset
    inc TextIdx
    jmp txt_loadChar_v3

; Overflow or even
@overflow:
    sta ChrOffset

    lda ChrBufferIdx
    clc
    adc #8
    sta ChrBufferIdx
    inc TextIdx
    jmp txt_loadChar_v3

TextPrepare_v3:
    ; Start by clearing the buffer so we don't
    ; have to do it later (and screw it up).
    jsr TextClearBuffer

    ldx #0
    stx ChrOffset
    stx TextIdx
    stx ChrBufferIdx

txt_loadChar_v3:
    ; Load a character from text
    ldy TextIdx
    ldx TextBuffer, y
    beq @exit  ; Null terminated name

    ; Check for end (in characters)
    cpy #21 ; Length of the buffer
    bcc @noExit

@exit:
    lda #$FF
    sta ChrBufferReady
    rts

@noExit:
    cpx #$FF    ; check for space
    beq txt_InsertSpace_v3

    ; Get width
    lda FontWidths, x

    ; Find overflow ammount
    ; Curret offset + character width - 8
    sta ChrWidth    ; This might not be needed
    clc
    adc ChrOffset
    sec
    sbc #8
    ; A now holds number of columns that overflow
    sta ChrOverflow

    ; Character ID -> word offset
    txa
    asl a
    tax

    ; Lookup tile data
    lda FontLookup, x
    sta TextPointer
    lda FontLookup+1, x
    sta TextPointer+1

    lda #0
    sta ChrCurrentRow

; Start of orig row loop
    ldy ChrCurrentRow ; 4
    ldx #0
    .repeat 8, i
    lda (TextPointer), y ; 3 * 8   ; get tile data byte for current row
    sta WorkingRuneA+i   ; 4 * 8
    stx WorkingRuneB+i
    iny ; 2 * 8
    .endrepeat

    ; get the absolute value of ChrOffset
    bit ChrOffset
    bpl :+

    lda #0
    sec
    sbc ChrOffset
    tax
    jmp :++
:
    ldx ChrOffset

:
    lda txt_ShiftJmpTable_Lo, x ;4
    sta AddressPointer0+0 ; 3
    lda txt_ShiftJmpTable_Hi, x ;4
    sta AddressPointer0+1 ; 3
    jmp (AddressPointer0); 5

txt_ShiftJmpTable_Hi:
    .hibytes txt_Shift0
    .hibytes txt_Shift1
    .hibytes txt_Shift2
    .hibytes txt_Shift3
    .hibytes txt_Shift4
    .hibytes txt_Shift5
    .hibytes txt_Shift6
    .hibytes txt_Shift7

txt_ShiftJmpTable_Lo:
    .lobytes txt_Shift0
    .lobytes txt_Shift1
    .lobytes txt_Shift2
    .lobytes txt_Shift3
    .lobytes txt_Shift4
    .lobytes txt_Shift5
    .lobytes txt_Shift6
    .lobytes txt_Shift7

txt_Shift7:
    .repeat 8, i
    ror WorkingRuneA+i
    ror WorkingRuneB+i
    .endrepeat
txt_Shift6:
    .repeat 8, i
    ror WorkingRuneA+i
    ror WorkingRuneB+i
    .endrepeat
txt_Shift5:
    .repeat 8, i
    ror WorkingRuneA+i
    ror WorkingRuneB+i
    .endrepeat
txt_Shift4:
    .repeat 8, i
    ror WorkingRuneA+i
    ror WorkingRuneB+i
    .endrepeat
txt_Shift3:
    .repeat 8, i
    ror WorkingRuneA+i
    ror WorkingRuneB+i
    .endrepeat
txt_Shift2:
    .repeat 8, i
    ror WorkingRuneA+i
    ror WorkingRuneB+i
    .endrepeat
txt_Shift1:
    .repeat 8, i
    ror WorkingRuneA+i
    ror WorkingRuneB+i
    .endrepeat
txt_Shift0:

    ; OR the first tile onto the current tile
    ldx ChrBufferIdx
    .repeat 8, i
    lda WorkingRuneA+i
    ora ChrBuffer+i, x
    sta ChrBuffer+i, x
    .endrepeat

    ; copy the second tile onto the next (blank) tile
    .repeat 8, i
    lda WorkingRuneB+i
    sta ChrBuffer+8+i, x
    .endrepeat

    lda ChrBufferIdx
    clc
    adc #8
    sta ChrBufferIdx

    ; A < 0     Room left on tile
    ; A == 0    No room, no overflow
    ; A > 0     Overflow into next tile
    lda ChrOverflow
    beq @tileEven
    cmp #0
    bpl @overflow

    ; Underflow
    lda ChrWidth
    clc
    adc ChrOffset
    sta ChrOffset

    ; Back up the buffer index to the start
    ; of the previous tile
    lda ChrBufferIdx
    sec
    sbc #8
    sta ChrBufferIdx
    jmp @loadNext

@tileEven:
    lda #0
    sta ChrOffset

    ldx ChrBufferIdx
    .repeat 8, I
    sta ChrBuffer+I, x
    .endrepeat

@loadNext:
    ; Move to next letter
    inc TextIdx

    jmp txt_loadChar_v3

; Second tile
@overflow:
    lda #0
    sta ChrCurrentRow

    ; ChrShiftLeft has the number of overflowed
    ; columns. This needs to be the number of times
    ; to shift left instead (like the name suggests)
    ;lda ChrWidth
    ;clc
    ;adc #8
    ;sec
    ;sbc ChrOffset
    ;sta ChrOffset

    lda #8
    sec
    sbc ChrOffset
    sta ChrShiftLeft

    ; Next char's offset
    lda ChrWidth
    sec
    sbc ChrShiftLeft
    sta ChrOffset

    ; Back up a tile
    ;lda ChrBufferIdx
    ;sec
    ;sbc #8
    ;sta ChrBufferIdx

    inc TextIdx
    jmp txt_loadChar_v3

txt_InsertSpace_v2:
    lda #SPACE_WIDTH
    sta ChrWidth
    clc
    adc ChrOffset
    sec
    sbc #8
    cmp #0
    bpl @overflow

    ; Underflow
    lda #SPACE_WIDTH
    clc
    adc ChrOffset
    sta ChrOffset
    inc TextIdx
    jmp txt_loadChar_v2

; Overflow or even
@overflow:
    sta ChrOffset

    lda ChrBufferIdx
    clc
    adc #8
    sta ChrBufferIdx
    inc TextIdx
    jmp txt_loadChar_v2

TextPrepare_v2:
    ; Start by clearing the buffer so we don't
    ; have to do it later (and screw it up).
    jsr TextClearBuffer

    ldx #0
    stx ChrOffset
    stx TextIdx
    stx ChrBufferIdx

txt_loadChar_v2:
    ; Load a character from text
    ldy TextIdx
    ldx TextBuffer, y
    beq @exit  ; Null terminated name

    ; Check for end (in characters)
    cpy #21 ; Length of the buffer
    bcc @noExit

@exit:
    lda #$FF
    sta ChrBufferReady
    rts

@noExit:
    cpx #$FF    ; check for space
    beq txt_InsertSpace_v2

    ; Get width
    lda FontWidths, x

    ; Find overflow ammount
    ; Curret offset + character width - 8
    sta ChrWidth    ; This might not be needed
    clc
    adc ChrOffset
    sec
    sbc #8
    ; A now holds number of columns that overflow
    sta ChrOverflow

    ; Character ID -> word offset
    txa
    asl a
    tax

    ; Lookup tile data
    lda FontLookup, x
    sta TextPointer
    lda FontLookup+1, x
    sta TextPointer+1

    lda #0
    sta ChrCurrentRow

; Start of orig row loop
    ldy ChrCurrentRow ; 4
    .repeat 8, i
    lda (TextPointer), y ; 3 * 8   ; get tile data byte for current row
    sta WorkingRuneA+i   ; 4 * 8
    iny ; 2 * 8
    .endrepeat

; Shift row to start offset
    ldx ChrOffset ; 4
@rightShiftLoop:
    cpx #0 ; 2
    beq @rightShiftDone ; 2/3
    ;lsr a
    .repeat 8, i
    lsr WorkingRuneA+i; 6 * 8
    .endrepeat
    dex ; 2
    jmp @rightShiftLoop ; 3

@rightShiftDone:

    ; OR onto dest byte
    ldx ChrBufferIdx ; 4
    .repeat 8, i
    lda WorkingRuneA+i  ; 4 * 8
    ora ChrBuffer+i, x ; 4 * 8
    sta ChrBuffer+i, x ; 5 * 8
    .endrepeat
    lda ChrBufferIdx ; 4
    clc ; 2
    adc #8 ; 2
    sta ChrBufferIdx ; 4

    ; End of orig row loop
    ;inc ChrCurrentRow
    ;ldy ChrCurrentRow
    ;cpy #8
    ;bne @rowLoop

    ; A < 0     Room left on tile
    ; A == 0    No room, no overflow
    ; A > 0     Overflow into next tile
    lda ChrOverflow
    beq @tileEven
    cmp #0
    bpl @overflow

    ; Underflow
    lda ChrWidth
    clc
    adc ChrOffset
    sta ChrOffset

    ; Back up the buffer index to the start
    ; of the previous tile
    lda ChrBufferIdx
    sec
    sbc #8
    sta ChrBufferIdx
    jmp @loadNext

@tileEven:
    lda #0
    sta ChrOffset

    ldx ChrBufferIdx
    .repeat 8, I
    sta ChrBuffer+I, x
    .endrepeat

@loadNext:
    ; Move to next letter
    inc TextIdx

    jmp txt_loadChar_v2

; Second tile
@overflow:
    lda #0
    sta ChrCurrentRow

    ; ChrShiftLeft has the number of overflowed
    ; columns. This needs to be the number of times
    ; to shift left instead (like the name suggests)
    lda #8
    sec
    sbc ChrOffset
    sta ChrShiftLeft
    ;lda ChrOffset
    ;eor #$FF
    ;sta ChrShiftLeft

;@rowOverflow:
    ldy ChrCurrentRow
    .repeat 8, i
    lda (TextPointer), y
    sta WorkingRuneA+i
    iny
    .endrepeat

; Shift the overflow data
    ldx ChrShiftLeft
@leftShiftLoop:
    cpx #0
    beq @leftShiftDone
    ;asl a
    .repeat 8, i
    lsr WorkingRuneA+i
    .endrepeat
    dex
    jmp @leftShiftLoop

@leftShiftDone:
    ldx ChrBufferIdx
    .repeat 8, i
    lda WorkingRuneA+i
    sta ChrBuffer+i, x
    .endrepeat
    ;inc ChrBufferIdx

    lda ChrBufferIdx
    clc
    adc #8
    sta ChrBufferIdx
    ;inc ChrCurrentRow
    ;ldy ChrCurrentRow
    ;cpy #8
    ;bne @rowOverflow

    ; Next char's offset
    lda ChrWidth
    sec
    sbc ChrShiftLeft
    sta ChrOffset

    ; Back up a tile
    lda ChrBufferIdx
    sec
    sbc #8
    sta ChrBufferIdx

    inc TextIdx
    jmp txt_loadChar_v2

txt_InsertSpace:
    lda #SPACE_WIDTH
    sta ChrWidth
    clc
    adc ChrOffset
    sec
    sbc #8
    cmp #0
    bpl @overflow

    ; Underflow
    lda #SPACE_WIDTH
    clc
    adc ChrOffset
    sta ChrOffset
    inc TextIdx
    jmp txt_loadChar

; Overflow or even
@overflow:
    sta ChrOffset

    lda ChrBufferIdx
    clc
    adc #8
    sta ChrBufferIdx
    inc TextIdx
    jmp txt_loadChar

; Prepares a CHR buffer using the text in TextBuffer
TextPrepare:
    ; Start by clearing the buffer so we don't
    ; have to do it later (and screw it up).
    jsr TextClearBuffer

    ldx #0
    stx ChrOffset
    stx TextIdx
    stx ChrBufferIdx

txt_loadChar:
    ; Load a character from text
    ldy TextIdx
    ldx TextBuffer, y
    beq @exit  ; Null terminated name

    ; Check for end (in characters)
    cpy #21 ; Length of the buffer
    bcc @noExit

@exit:
    lda #$FF
    sta ChrBufferReady
    rts

@noExit:
    cpx #$FF    ; check for space
    beq txt_InsertSpace

    ; Get width
    lda FontWidths, x

    ; Find overflow ammount
    ; Curret offset + character width - 8
    sta ChrWidth    ; This might not be needed
    clc
    adc ChrOffset
    sec
    sbc #8
    ; A now holds number of columns that overflow
    sta ChrOverflow

    ; Character ID -> word offset
    txa
    asl a
    tax

    ; Lookup tile data
    lda FontLookup, x
    sta TextPointer
    lda FontLookup+1, x
    sta TextPointer+1

    lda #0
    sta ChrCurrentRow

@rowLoop:
    ldy ChrCurrentRow   ; 4
    lda (TextPointer), y ; 5   ; get tile data byte for current row

; Shift row to start offset
    ldx ChrOffset ; 4
@rightShiftLoop:
    cpx #0 ; 2
    beq @rightShiftDone ; 2/3
    lsr a ; 2
    dex ; 2
    jmp @rightShiftLoop ; 3

@rightShiftDone:

    ; OR onto dest byte
    ldx ChrBufferIdx ; 4
    ora ChrBuffer, x ; 4
    sta ChrBuffer, x ; 5
    inc ChrBufferIdx ; 6

    inc ChrCurrentRow ; 6
    ldy ChrCurrentRow ; 4
    cpy #8 ; 2
    bne @rowLoop ; 3/2

    ; A < 0     Room left on tile
    ; A == 0    No room, no overflow
    ; A > 0     Overflow into next tile
    lda ChrOverflow
    beq @tileEven
    cmp #0
    bpl @overflow

    ; Underflow
    lda ChrWidth
    clc
    adc ChrOffset
    sta ChrOffset

    ; Back up the buffer index to the start
    ; of the previous tile
    lda ChrBufferIdx
    sec
    sbc #8
    sta ChrBufferIdx
    jmp @loadNext

@tileEven:
    lda #0
    sta ChrOffset

    ldx ChrBufferIdx
    .repeat 8, I
    sta ChrBuffer+I, x
    .endrepeat

@loadNext:
    ; Move to next letter
    inc TextIdx

    jmp txt_loadChar

; Second tile
@overflow:
    lda #0
    sta ChrCurrentRow

    ; ChrShiftLeft has the number of overflowed
    ; columns. This needs to be the number of times
    ; to shift left instead (like the name suggests)
    lda #8
    sec
    sbc ChrOffset
    sta ChrShiftLeft
    ;lda ChrOffset
    ;eor #$FF
    ;sta ChrShiftLeft

@rowOverflow:
    ldy ChrCurrentRow
    lda (TextPointer), y

; Shift the overflow data
    ldx ChrShiftLeft
@leftShiftLoop:
    cpx #0
    beq @leftShiftDone
    asl a
    dex
    jmp @leftShiftLoop

@leftShiftDone:
    ldx ChrBufferIdx
    sta ChrBuffer, x
    inc ChrBufferIdx

    inc ChrCurrentRow
    ldy ChrCurrentRow
    cpy #8
    bne @rowOverflow

    ; Next char's offset
    lda ChrWidth
    sec
    sbc ChrShiftLeft
    sta ChrOffset

    ; Back up a tile
    lda ChrBufferIdx
    sec
    sbc #8
    sta ChrBufferIdx

    inc TextIdx
    jmp txt_loadChar

FontData:
    .include "font.i"

FontLookup:
    ; Calculate the number of characters and error if it's more than 127.
    ; Only allow 127 characters due to using only one address lookup table.
    CHR_COUNT = (* - FontData) / 8
    .out .sprintf("CHR_COUNT: %d", CHR_COUNT)
    .assert CHR_COUNT < 127, error, "More than 127 characters!"

    ; Calculate a lookup table for the font's CHR data.
    .repeat CHR_COUNT, I
        .word (FontData + (I * 8))
    .endrepeat

; Width in pixels for each character
FontWidths:
    .include "font.widths.i"
