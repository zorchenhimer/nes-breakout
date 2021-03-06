; asmsyntax=ca65

; == Byte data format ==
; First byte:
;
;     01le tttt
;     |||| ++++-- Tile type (0 doesn't have a second byte)
;     |||+------- Has this tile been entered/interacted with?
;     ||+-------- Has this byte been loaded (child spawn only)?
;     ++--------- Always 01
;
; Second byte:
;
;     1ddd dddd
;     |+++-++++-- Tile value.
;     |             For child: if loaded, its index in RAM.
;     |                        if not loaded, its map ID to load.
;     |             For health: remaining hits to destroy tile
;     |             For powerup/down: ID of drop
;     +---------- Always 1
;
; Tile types:
;
;     %0        No brick
;     %10       Standard brick (health)
;     %110      Child spawn
;     %1110     Powerup
;     %11110    PowerDown ;; nope
;     %11110   Half brick

.import main_Index_Maps
.import child_Index_Maps

; Load a child map into RAM starting at $6000
; Input: A
; Output: $6000
LoadChildMap:
    sta IdxD ; Map ID in ROM
    asl a
    tax

    ; Save bank we're coming from
    lda $8000
    sta LastBank

    ; Swap to data bank
    lda #1
    jsr MMC1_Select_Page

    ; Load up a pointer to the map's metadata
    lda child_Index_Maps+0, x
    sta AddressPointer0+0
    lda child_Index_Maps+1, x
    sta AddressPointer0+1

    jsr map_LoadMetaData

    lda NextChildOffset
    cmp #102
    bcs @done   ; too many maps loaded.  abort to not break things.

    sta ChildId ; update the ID.  This will be written to the brick in memory.
    inc NextChildOffset

    asl a
    tax

    lda Child_Map_Addresses, x
    sta AddressPointer0
    lda Child_Map_Addresses+1, x
    sta AddressPointer0+1

    ; Get the flags and rewrite just the health
    lda TmpZ
    bpl @noGrav
    lda #GRAVITY_VALUE
    jmp :+
@noGrav:
    lda #0
:
    ldy #$48
    sta (AddressPointer0), y

    bit TmpZ
    bvc @noRandoDrops
    ; TODO save it lol
@noRandoDrops:

    lda TmpZ
    and #$1F
    sta TmpZ

    lda #72
    sta TmpW    ; tile count
@loadLoop:
    jsr map_ReadTile
    jsr map_WriteData
    dec TmpW
    bne @loadLoop

    ; Store the child map ID in RAM next to the map data.
    lda IdxD
    ldy #1
    sta (AddressPointer0), y

    ; TODO: put a return address pointer here too to
    ;       allow nested child maps.

@done:
    ; Swap back to last bank
    lda LastBank
    jmp MMC1_Select_Page

map_WriteData:
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

    cmp #4 ; check for half brick
    ;beq @halfBrick
    bne :+
    rts
:
    ldy IdxB    ; load index
    inc IdxB    ; increment for next read
    lda (AddressPointer2), y    ; load value
    jmp @writeValue

@healthBrick:
    lda TmpZ    ; health start value is global to map

@writeValue:
    dec TmpW
    ora #$80
    ldy #0
    sta (AddressPointer0), y    ; write value
    jsr IncPointer0
    rts

@noBrick:
    lda #0
    sta (AddressPointer0), y
    jsr IncPointer0
    rts

map_LoadMetaData:
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
    rts

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
    lda main_Index_Maps+0, x
    sta AddressPointer0+0
    lda main_Index_Maps+1, x
    sta AddressPointer0+1

    jsr map_LoadMetaData

    ; Get the flags and rewrite just the health
    lda TmpZ
    bpl @noGrav
    lda #GRAVITY_VALUE
    jmp :+
@noGrav:
    lda #0
:
    sta Gravity_MainMap

    bit TmpZ
    bvc @noRandoDrops
    ; TODO save it lol
@noRandoDrops:

    lda TmpZ
    and #$20
    beq @noRandoChildren
    ; TODO save it lol
@noRandoChildren:

    lda TmpZ
    and #$1F
    sta TmpZ

    ; Load map dest address in pointer0
    lda #<CurrentMap
    sta AddressPointer0+0
    lda #>CurrentMap
    sta AddressPointer0+1

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
    jsr map_WriteData
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

; Last address for the main map
Last_Map_Tile_Address:
    .word (BOARD_WIDTH * BOARD_HEIGHT) + CurrentMap

Child_Map_Addresses:
    ; RAM will not fit any more than 102 decoded child maps
    ; at 12x6 tiles (72 bytes, rounded up to 80).
    .repeat 102, i
    .word ($6000 + (80 * i))
    .endrepeat
