; asmsyntax=ca65

.import Index_Maps

; Expects a map Id in A and loads the map with that Id
; into RAM starting at the CurrentMap label
LoadMap:
    asl a
    tax

    ; Save bank we're coming from
    lda $8000
    sta LastBank

    ; TODO: lookup table for banks?
    ; Swap to data bank
    lda #1
    jsr MMC1_Select_Page

    ; Load up a pointer to the map's metadata
    lda Index_Maps+0, x
    sta AddressPointer0+0
    lda Index_Maps+1, x
    sta AddressPointer0+1

    ldy #0
    ; Load pointer to tile data
    lda (AddressPointer0), y
    sta AddressPointer1+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer1+1

    ; Load pointer to value data
    iny
    lda (AddressPointer0), y
    sta AddressPointer2+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer2+1

    ; Load the start health value
    iny
    lda (AddressPointer0), y
    sta TmpZ

    lda #0
    sta IdxB    ; Value offset
    lda #$FF
    sta IdxA    ; Data offset
    lda #1      ; init to 1 to load first byte
    sta TmpX    ; Bit counter

    ; Load map dest address in pointer0
    lda #<CurrentMap
    sta AddressPointer0+0
    lda #>CurrentMap
    sta AddressPointer0+1

; == Byte data format ==
; First byte:
; 01le tttt
; |||| ++++-- Tile type (0 doesn't have a second byte)
; |||+------- Has this tile been entered/interacted with?
; ||+-------- Has this byte been loaded (child spawn only)?
; ++--------- Always 01
;
; Second byte:
; 1ddd dddd
; |+++-++++-- Tile value.
; |             For child: if loaded, its index in RAM.
; |                        if not loaded, its map ID to load.
; |             For health: remaining hits to destroy tile
; |             For powerup/down: ID of drop
; +---------- Always 1

; Tile types:
; %0        No brick
; %10       Standard brick (health)
; %110      Child spawn
; %1110     Powerup
; %11110    PowerDown

; Main loop to load map
@loadLoop:
    ; check for end-of-map
    lda AddressPointer0+1
    cmp Last_Map_Tile_Address+1
    bne :+
    lda AddressPointer0+0
    cmp Last_Map_Tile_Address+0
    bcc :+
    ; we done
    jmp @done
:

    jsr map_ReadTile
    ldy #0
    lda TmpY
    beq @noBrick

    ; Write the first byte
    ora #$40
    sta (AddressPointer0), y
    jsr IncPointer0

    ; Write the value byte
    and #$0F
    cmp #1
    beq @healthBrick

    ldy IdxB    ; load index
    inc IdxB    ; increment for next read
    lda (AddressPointer2), y    ; load value
    jmp @writeValue

@healthBrick:
    lda TmpZ    ; health start value is global to map

@writeValue:
    ora #$80
    ldy #0
    sta (AddressPointer0), y    ; write value
    jsr IncPointer0
    jmp @loadLoop

@noBrick:
    lda #0
    sta (AddressPointer0), y
    jsr IncPointer0
    jmp @loadLoop

@done:
    ; Swap back to last bank
    lda LastBank
    jsr MMC1_Select_Page
    rts

; Start at the current offset in the encoded data
; and return a single tile type.
map_ReadTile:
    ; Things to keep track of:
    ;   IdxA - current data offset
    ;   TmpX - number of bits shifted off current byte
    ;   TmpY - output value
    ;   IdxC - current data byte

    lda #0
    sta TmpY

@top:
    dec TmpX     ; decrement bit count
    bne @shift   ; load next byte after eight bits

    inc IdxA    ; increment data index
    lda #8
    sta TmpX    ; reset bit count

    ; Load current data byte
    ldy IdxA
    lda (AddressPointer1), y
    sta IdxC

@shift:
    ; Shift data off until zero
    asl IdxC
    bcc @done
    inc TmpY
    jmp @top

@done:
    rts

Last_Map_Tile_Address:
    .word (BOARD_WIDTH * BOARD_HEIGHT) + CurrentMap - 1
