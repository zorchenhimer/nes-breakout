; asmsyntax=ca65

.segment "PAGE_FIXED"

    ; Redefining ASCII code points
    ;.include "font.map.asm"
    ;.charmap ' ', $FF   ; The only one that can't really be auto-generated

    SPACE_WIDTH = 5

WriteBufferUnrolled:
    lda #$00
    sta $2006
    sta $2006

    .repeat 21, B
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

; A has count
; X has the BG palette value thing in it
WriteTextBuffer:
    sta ChrCount
    txa
    pha
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
    ldy ChrCurrentRow
    lda (TextPointer), y    ; get tile data byte for current row

; Shift row to start offset
    ldx ChrOffset
@rightShiftLoop:
    cpx #0
    beq @rightShiftDone
    lsr a
    dex
    jmp @rightShiftLoop

@rightShiftDone:

    ; OR onto dest byte
    ldx ChrBufferIdx
    ora ChrBuffer, x
    sta ChrBuffer, x
    inc ChrBufferIdx

    inc ChrCurrentRow
    ldy ChrCurrentRow
    cpy #8
    bne @rowLoop

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
