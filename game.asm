; asmsyntax=ca65

Initial_Ball_Speed_WHOLE = 3
Initial_Ball_Speed_FRACT = 0

WALL_RIGHT = $F5
WALL_LEFT = $0A
WALL_TOP = $11
WALL_BOTTOM = $DC

BALL_SPRITE_OFFSET_X = 3
BALL_SPRITE_OFFSET_Y = 3

Pal_Game:
    .byte $0F, $0A, $1A, $2A

Pal_GameSprites:
    .byte $0F, $26, $00, $30

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
    ;lda #0
    ;sta Sprites+3
    ;lda #120
    ;sta Sprites+0

    ;lda #1
    ;sta Sprites+1
    ;lda #1
    ;sta Sprites+2

    lda #$00
    sta BallX
    sta BallY

    lda #$80
    sta BallX+1
    lda #$70
    sta BallY+1

    lda #Initial_Ball_Speed_FRACT
    sta BallSpeedY
    ;lda #$00
    sta BallSpeedX

    ;lda #$01
    lda #Initial_Ball_Speed_WHOLE
    sta BallSpeedY+1
    ;lda #$00
    sta BallSpeedX+1

    lda #4
    jsr LoadMap
    jsr DrawCurrentMap

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
    jsr CheckWallCollide
    jsr UpdateBallSprite

; Attempted to change the BG color on sprite zero.
; Doesn't work.
;    lda #$3F
;    ldx #$00
;    ldy #%10011000
;    jsr WaitForSpriteZero
;
;.repeat 37
;    nop
;.endrepeat
;
;    sty $2000
;
;    sta $2006
;    stx $2006
;    stx $2007
;
;    ; Select first nametable
;    sty $2000
;    stx $2005
;    stx $2005

    jsr WaitForNMI
    jmp Frame_Game

NMI_Game:
    jsr WriteSprites

    lda #$3F
    sta $2006
    lda #$00
    sta $2006
    lda #$0F
    sta $2007

    lda #0
    sta $2005
    sta $2005

    lda #%10011000
    sta $2000

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
    rts

UpdateBallSprite:
    ; Update sprite coordinates
    lda BallX+1
    sec
    sbc #BALL_SPRITE_OFFSET_X
    sta Sprites+7

    lda BallY+1
    sec
    sbc #BALL_SPRITE_OFFSET_Y
    sta Sprites+4
    rts

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

GetBallHorizDirection:
    lda BallSpeedX+1
    beq @fractional
    jmp @chk

@fractional:
    lda BallSpeedX

@chk:
    bpl @positive
    lda #0
    rts
@positive:
    lda #1
    rts

GetBallVertDirection:
    lda BallSpeedY+1
    beq @fractional
    jmp @chk

@fractional:
    lda BallSpeedY

@chk:
    bpl @positive
    lda #0
    rts
@positive:
    lda #1
    rts

CheckWallCollide:
    jsr GetBallVertDirection
    bne @goingDown
    ; Going up
    lda BallY+1
    cmp #WALL_TOP
    beq @bounceVertTop
    bcc @bounceVertTop
    jmp @checkHoriz

@goingDown:
    lda BallY+1
    cmp #WALL_BOTTOM
    bcs @bounceVertBottom
    jmp @checkHoriz

@bounceVertTop:
    lda #WALL_TOP
    sec
    sbc BallY+1

    clc
    adc #WALL_TOP
    sta BallY+1
    jmp @bounceVert

@bounceVertBottom:
    lda BallY+1
    sec
    sbc #WALL_BOTTOM
    sta TmpX

    lda #WALL_BOTTOM
    sbc TmpX
    sta BallY+1

@bounceVert:
    lda #$00
    sec
    sbc BallSpeedY
    sta BallSpeedY

    lda #$00
    sbc BallSpeedY+1
    sta BallSpeedY+1

@checkHoriz:
    jsr GetBallHorizDirection
    bne @goingRight
    ; Going left
    lda BallX+1
    cmp #WALL_LEFT
    beq @bounceHorizLeft
    bcc @bounceHorizLeft
    rts ; return early

@goingRight:
    lda BallX+1
    cmp #WALL_RIGHT
    bcs @bounceHorizRight
    rts ; return early

@bounceHorizLeft:
    ; Get diff = (wall - ball)
    lda #WALL_LEFT
    sec
    sbc BallX+1
    ; diff in A

    ; Add difference to wall coord
    clc
    adc #WALL_LEFT
    sta BallX+1
    jmp @bounceHoriz

@bounceHorizRight:
    lda BallX+1
    sec
    sbc #WALL_RIGHT
    sta TmpX    ; wall - ball difference

    lda #WALL_RIGHT
    sbc TmpX
    sta BallX+1

@bounceHoriz:
    lda #$00
    sec
    sbc BallSpeedX
    sta BallSpeedX

    lda #$00
    sbc BallSpeedX+1
    sta BallSpeedX+1
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

; Read the current map in RAM and draw it to the screen
DrawCurrentMap:
    lda #$90
    sta $2000

    ldy #0
    sty TmpX

@loop:
    ; Load up current row's RAM address
    ldy TmpX
    lda Row_Addresses_Low, y
    sta AddressPointer0
    lda Row_Addresses_High, y
    sta AddressPointer0+1

    ; Draw it
    jsr game_DrawRow

    ; Are we done?
    inc TmpX
    lda TmpX
    cmp #BOARD_HEIGHT
    bne @loop
    rts


game_DrawRow:
    ; Lookup ppu address for row
    lda TmpX
    asl a
    tax
    bit $2002
    lda Index_PpuBrickRows+1, x
    sta $2006
    lda Index_PpuBrickRows+0, x
    sta $2006

    ldy #0
@loop:
    lda (AddressPointer0), y
    beq @noTile

    ; Id -> lookup index
    and #$0F
    sec
    sbc #1  ; "health" is id 1, but index 0
    asl a
    tax

    lda Index_TileDefs, x
    sta $2007
    lda Index_TileDefs+1, x
    sta $2007

    iny
    iny
    cpy #BOARD_WIDTH
    bne @loop
    rts

@noTile:
    lda #NoTileID
    sta $2007

    iny
    cpy #BOARD_WIDTH
    bne @loop
    rts

NoTileID = $00
Index_TileDefs:
    .byte $02, $03  ; Health
    .byte $04, $05  ; Spawn
    .byte $06, $07  ; Powerup/down

Index_PpuBrickRows:
.repeat BOARD_HEIGHT, i
    .word $2000 + (((BOARD_OFFSET_Y/8) * 32) + (BOARD_OFFSET_X/8)) + i * 32
    ;.out .sprintf("PPU Row Address: %x", ($2000 + (((BOARD_OFFSET_Y/8) * 32) + (BOARD_OFFSET_X/8) + i * 32)))
.endrepeat
