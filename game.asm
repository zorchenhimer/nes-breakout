; asmsyntax=ca65

Pal_Game:
    .byte $0F, $0A, $1A, $2A

Pal_GameSprites:
    .byte $0F, $07, $17, $27

Init_Game:
    NMI_Disable

    ; Disable drawing BG and sprites
    lda #$00
    sta $2001

    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    ; Load up a palette
.repeat 4, i
    lda Pal_Game+i
    sta $2007
.endrepeat

    lda #$3F
    sta $2006
    lda #$10
    sta $2006

    ; Load up another palette
.repeat 4, i
    lda Pal_GameSprites+i
    sta $2007
.endrepeat

    lda #0
    jsr FillNametable2
    jsr ClearAttrTable0

    lda #1
    jsr LoadChrData

    jsr ClearSprites

    ; Y, X
    lda #$80
    sta Sprites+4
    sta Sprites+7

    ; Tile
    lda #$10
    sta Sprites+5

    ; Attributes
    lda #0
    sta Sprites+6

    jsr WriteSprites

    ; Draw top two rows
    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda #$01
    ldx #64
:
    sta $2007
    dex
    bne :-

    ; draw bottom two rows
    lda #$23
    sta $2006
    lda #$80
    sta $2006

    lda #$01
    ldx #64
:
    sta $2007
    dex
    bne :-

    ; Draw Left
    lda #%10011100
    sta $2000

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda #$01
    ldx #30
:
    sta $2007
    dex
    bne :-

    ; Draw Right
    lda #$20
    sta $2006
    lda #$1F
    sta $2006

    lda #$01
    ldx #30
:
    sta $2007
    dex
    bne :-

    ; Sprite zero
    ; TODO: Try to change the background color
    ; during H-Blank with this as the trigger
    lda #247
    sta Sprites+3
    lda #120
    sta Sprites+0

    lda #0
    sta Sprites+1
    lda #1
    sta Sprites+2

    lda #$00
    sta BallX
    sta BallY

    lda #$80
    sta BallX+1
    lda #$70
    sta BallY+1

    ; Select first nametable
    lda #%10011000
    sta $2000

    lda #%00011110
    sta $2001

    lda #$00
    sta $2005
    sta $2005

    NMI_Set NMI_Game

AccelSpeed = 1

Frame_Game:
    jsr ReadControllers

    lda #BUTTON_UP
    and controller1
    ;jsr ButtonPressedP1
    beq :+

    ; Move ball up
    lda BallSpeedY
    sec
    sbc #AccelSpeed
    sta BallSpeedY

    lda BallSpeedY+1
    sbc #0
    sta BallSpeedY+1
:

    lda #BUTTON_DOWN
    ;jsr ButtonPressedP1
    and controller1
    beq :+

    ; Move ball down
    lda BallSpeedY
    clc
    adc #AccelSpeed
    sta BallSpeedY

    lda BallSpeedY+1
    adc #0
    sta BallSpeedY+1
:

    lda #BUTTON_LEFT
    and controller1
    beq :+

    lda BallSpeedX
    sec
    sbc #AccelSpeed
    sta BallSpeedX

    lda BallSpeedX+1
    sbc #0
    sta BallSpeedX+1
:

    lda #BUTTON_RIGHT
    and controller1
    beq :+

    lda BallSpeedX
    clc
    adc #AccelSpeed
    sta BallSpeedX

    lda BallSpeedX+1
    adc #0
    sta BallSpeedX+1
:
    jsr UpdateBallCoords
    jsr WaitForNMI
    jmp Frame_Game

NMI_Game:
    jsr WriteSprites
    dec Sleeping
    rti

; Read BallX and BallY coords and translate
; them to sprite coords
UpdateBallCoords:
    ; Update coords in memory using the speeds
    lda BallX
    clc
    adc BallSpeedX
    sta BallX

    lda BallX+1
    adc BallSpeedX+1
    sta BallX+1

@vertical:
    lda BallY
    clc
    adc BallSpeedY
    sta BallY

    lda BallY+1
    adc BallSpeedY+1
    sta BallY+1

    ; Update sprite coordinates
    lda BallX+1
    sec
    sbc #4
    sta Sprites+7

    lda BallY+1
    sec
    sbc #4
    sta Sprites+4
    rts

; Row witdh of 26
BOARD_WIDTH = 26
BOARD_HEIGHT = 12
BOARD_OFFSET_Y = 24
BOARD_OFFSET_X = 24
; Row with of 24
;BOARD_WIDTH = 24
;BOARD_HEIGHT = 12
;BOARD_OFFSET_Y = 24
;BOARD_OFFSET_X = 32

; Reads sprite coordinates and returns map tile index
; TODO: do this correctly, lol
; AddressPointer0 holds a pointer to the start of the
; row in memory.  Y holds the offset from that pointer.
SpriteToTile:
    lda BallY+1
    sec
    ; Subtract offset
    sbc #BOARD_OFFSET_Y
    ; divide by 8
    lsr a
    lsr a
    lsr a
    ; Lookup that row's pointer
    tax
    lda Row_Addresses_Low, x
    sta AddressPointer0
    lda Row_Addresses_High, x
    sta AddressPointer0+1

    lda BallX+1
    sec
    ; Subtract offset
    sbc #BOARD_OFFSET_X
    ; divide by 8
    lsr a
    lsr a
    lsr a
    ; "Store" it
    tay
    rts

; TODO: Check side of brick collision for bounce.
CheckCollide:
    lda BallY+1
    ; Y >= BOARD_OFFSET_Y, continue
    cmp #BOARD_OFFSET_Y
    bcs :+
    ; Above board
    rts
:
    ; Y <= BOARD_HEIGHT + BOARD_OFFSET_Y, continue
    cmp #((BOARD_HEIGHT * 8) + BOARD_OFFSET_Y)
    beq :+
    bcc :+
    ; Below board
    rts
:

    lda BallX+1
    ; X >= BOARD_OFFSET_X, continue
    cmp #BOARD_OFFSET_X
    bcs :+
    ; Left of board
    rts
:
    ; X <= BOARD_WIDTH + BOARD_OFFSET_X, continue
    cmp #((BOARD_WIDTH * 8) + BOARD_OFFSET_X)
    beq :+
    bcc :+
    ; Right of board
    rts
:

    ; Ball is in board area.  Check for brick collision
    jsr SpriteToTile
    lda (AddressPointer0), y
    bne :+
    ; No tile
    rts
:
    bpl @DecodeFirstByte
    ; TODO: verify that this can never happen on first column
    dey
    lda (AddressPointer0), y

@DecodeFirstByte:
    ; Mask the brick type
    and #$0F
    asl a
    tax

    ; JMP to collision code for the given brick type
    lda Index_TileTypes+1, x
    pha
    lda Index_TileTypes, x
    pha
    rts

Index_TileTypes:
    .word Collide_Health-1
    .word Collide_Spawn-1
    .word Collide_Powerup-1
    .word Collide_Powerdown-1
    ; Add some more? idk

; Decriment health.  Break when it rolls under.
Collide_Health:
    rts

; Go to the child board
Collide_Spawn:
    rts

; Delete the brick, and spawn a sprite
Collide_Powerup:
    rts
Collide_Powerdown:
    rts

Row_Addresses_Low:
.repeat BOARD_HEIGHT, i
    .byte .lobyte(CurrentMap+(i*BOARD_WIDTH))
.endrepeat

Row_Addresses_High:
.repeat BOARD_HEIGHT, i
    .byte .hibyte(CurrentMap+(i*BOARD_WIDTH))
.endrepeat
