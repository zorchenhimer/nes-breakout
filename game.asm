; asmsyntax=ca65

Initial_Ball_Speed_WHOLE = 1
Initial_Ball_Speed_FRACT = 0

WALL_RIGHT = $F5
WALL_LEFT = $0A
WALL_TOP = $11
WALL_BOTTOM = $DD

BALL_SPRITE_OFFSET_X = 3
BALL_SPRITE_OFFSET_Y = 3

BALL_INIT_X = 60 ; $80
BALL_INIT_Y = 32 ; $C0

EDGE_COLLIDE_OFFSET = 3
POINT_COLLIDE_OFFSET = 2

START_MAP = 7

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

    lda #BALL_INIT_X
    sta BallX+1
    lda #BALL_INIT_Y
    sta BallY+1

    lda #Initial_Ball_Speed_FRACT
    sta BallSpeedY
    ;lda #$00
    sta BallSpeedX

    ;lda #$01
    lda #$00
    sta BallSpeedY+1
    lda #Initial_Ball_Speed_WHOLE
    sta BallSpeedX+1

    lda #START_MAP
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
    jsr CheckBrickCollide
    ;jsr CheckPaddleCollide ; todo
    jsr UpdateBallSprite

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

; Takes TmpX and TmpY pixel coordinates and returns
; tile row/column values in X and Y.
;
; X holds the row
; Y holds the column
PointToTile:
    lda TmpY
    sec
    ; Subtract offset
    sbc #BOARD_OFFSET_Y
    ; divide by 8
    lsr a
    lsr a
    lsr a
    ; Lookup that row's pointer
    tax

    lda TmpX
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

; 0 - Left
; 1 - Right
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

; 0 - Up
; 1 - Down
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
    jsr BounceVert

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
    ; traveling right
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
    jmp BounceHoriz

;; Brick Collision
CheckBrickCollide:
    ;; Check vertical points

    ; X is the same for top and bottom
    ; PointA
    lda BallX+1
    sec
    sbc #POINT_COLLIDE_OFFSET
    sta PointA_X

    ; PointB
    lda BallX+1
    clc
    adc #POINT_COLLIDE_OFFSET
    sta PointB_X

    ; Y is different depending on direction.
    jsr GetBallVertDirection
    beq @ballGoingUp
    ;; Ball is going down

    lda BallY+1
    clc
    adc #EDGE_COLLIDE_OFFSET
    sta PointA_Y
    sta PointB_Y
    jmp @vertCheck

@ballGoingUp:
    lda BallY+1
    sec
    sbc #EDGE_COLLIDE_OFFSET
    sta PointA_Y
    sta PointB_Y

@vertCheck:

    ; Check both points for collision
    jsr CheckTwoPointCollision
    bit CollisionRow_Ret
    bpl @noVertCollide

    ; Something collided, store it
    lda CollisionRow_Ret
    sta BrickRowIndex_Vert
    lda CollisionCol_Ret
    sta BrickColIndex_Vert
    jmp @checkHoriz

@noVertCollide:
    lda #0
    sta BrickRowIndex_Vert
    sta BrickColIndex_Vert

    ;; Check horizontal points
@checkHoriz:
    lda BallY+1
    sec
    sbc #POINT_COLLIDE_OFFSET
    sta PointA_Y

    lda BallY+1
    clc
    adc #POINT_COLLIDE_OFFSET
    sta PointB_Y

    jsr GetBallHorizDirection
    beq @ballGoingLeft
    ; going right
    lda BallX+1
    clc
    adc #EDGE_COLLIDE_OFFSET
    sta PointA_X
    sta PointB_X
    jmp @horizCheck

@ballGoingLeft:
    lda BallX+1
    sec
    sbc #EDGE_COLLIDE_OFFSET
    sta PointA_X
    sta PointB_X

@horizCheck:
    jsr CheckTwoPointCollision
    bit CollisionRow_Ret
    bpl @noHorizCollide

    ; Something collided, store it
    lda CollisionRow_Ret
    sta BrickRowIndex_Horiz
    lda CollisionCol_Ret
    sta BrickColIndex_Horiz
    jmp @actOnVert

@noHorizCollide:
    lda #0
    sta BrickRowIndex_Horiz
    sta BrickColIndex_Horiz

@actOnVert:
    ;; Act on vertictal collision
    bit BrickRowIndex_Vert
    bpl :+
    jsr DoVerticalBrickCollide

:   ; no vertical collide
    ;; Act on horizontal collision
    bit BrickRowIndex_Horiz
    bpl :+
    jmp DoHorizontalBrickCollide

:   ; no horizontal collide
    rts

;CheckBrickCollide_borked:
;    ;lda #(BallX+1 - POINT_COLLIDE_OFFSET)
;    lda BallX+1
;    sec
;    sbc #POINT_COLLIDE_OFFSET
;    sta TmpX
;
;    jsr GetBallVertDirection
;    beq @goingUpLeft
;    ; Get the two collide points, and check them
;
;    ; Left point
;    ;lda #(BallY+1 + EDGE_COLLIDE_OFFSET)
;    lda BallY+1
;    clc
;    adc #EDGE_COLLIDE_OFFSET
;    sta TmpY
;    jmp @pointLeftCheck
;
;@goingUpLeft:
;    ;lda #(BallY+1 - EDGE_COLLIDE_OFFSET)
;    lda BallY+1
;    sec
;    sbc #EDGE_COLLIDE_OFFSET
;    sta TmpY
;
;@pointLeftCheck:
;    jsr CheckPointCollide
;    beq @clearPointLeft
;    ;; TODO if collide, set a flag and check other point
;
;    stx BrickCollide1_Row
;    sty BrickCollide1_Col
;
;    lda #$80
;    ora BrickCollide1_Row
;    sta BrickCollide1_Row
;    jmp @pointRightCheck
;
;@clearPointLeft:
;    lda #0
;    sta BrickCollide1_Row
;
;@pointRightCheck:
;    ;lda #(BallX+1 + POINT_COLLIDE_OFFSET)
;    lda BallX+1
;    clc
;    adc #POINT_COLLIDE_OFFSET
;    sta TmpX
;
;    jsr GetBallVertDirection
;    beq @goingUpRight
;
;    ; Right point
;    ;lda #(BallY+1 + EDGE_COLLIDE_OFFSET)
;    lda BallY+1
;    clc
;    adc #EDGE_COLLIDE_OFFSET
;    sta TmpY
;    jmp @checkPointRight
;
;@goingUpRight:
;    ;lda #(BallY+1 - EDGE_COLLIDE_OFFSET)
;    lda BallY+1
;    sec
;    sbc #EDGE_COLLIDE_OFFSET
;    sta TmpY
;
;@checkPointRight:
;    jsr CheckPointCollide
;    beq @clearPointRight
;
;    stx BrickCollide2_Row
;    sty BrickCollide2_Col
;
;    lda #$80
;    ora BrickCollide2_Row
;    sta BrickCollide2_Row
;    jmp @checkPointsVert
;
;@clearPointRight:
;    lda #0
;    sta BrickCollide2_Row
;
;@checkPointsVert:
;    ;
;    bit BrickCollide1_Row
;    bpl @noPointLeft
;    bit BrickCollide2_Row
;    bpl @noPointRight
;
;;; Both points collided. Find collision between
;;; left and right points
;    ; X = X
;    ; Y = Y + distance from center to edge
;    lda BallX+1
;    sta TmpX
;
;    lda BallY+1
;    clc
;    adc #EDGE_COLLIDE_OFFSET
;    jsr CheckPointCollide
;
;    stx BrickCollide1_Row
;    sty BrickColIndex_Vert
;
;    lda #$80
;    ora BrickCollide1_Row
;    sta BrickRowIndex_Vert
;
;    jmp @checkHorizontal
;
;@noPointLeft:
;    bit BrickCollide2_Row
;    bpl @noVertCollide
;
;;; Just right point collided
;    lda BrickCollide2_Row
;    sta BrickRowIndex_Vert
;    lda BrickCollide2_Col
;    sta BrickColIndex_Vert
;
;    jmp @checkHorizontal
;
;@noPointRight:
;;; just Left collided
;    lda BrickCollide1_Row
;    sta BrickRowIndex_Vert
;    lda BrickCollide1_Col
;    sta BrickColIndex_Vert
;
;    jmp @checkHorizontal
;
;@noVertCollide:
;;; Neither collided
;    lda #0
;    sta BrickRowIndex_Vert
;    sta BrickColIndex_Vert
;    ;jmp @checkHorizontal
;
;;; Horizontal
;@checkHorizontal:
;    ; X = X + distance from center to edge
;    ; Y = Y + distance from midpoint to corner
;    lda BallY+1
;    sec
;    sbc #POINT_COLLIDE_OFFSET
;    sta TmpY
;
;    jsr GetBallHorizDirection
;    beq @goingLeftTop
;
;    lda BallX+1
;    clc
;    adc #EDGE_COLLIDE_OFFSET
;    sta TmpX
;    jmp @pointTopCheck
;
;@goingLeftTop:
;    lda BallX+1
;    sec
;    sbc #EDGE_COLLIDE_OFFSET
;    sta TmpX
;
;@pointTopCheck:
;    jsr CheckPointCollide
;    beq @clearPointTop
;
;    stx BrickCollide1_Row
;    sty BrickCollide1_Col
;
;    lda #$80
;    ora BrickCollide1_Row
;    sta BrickCollide1_Row
;    jmp @pointBottomCheck
;
;@clearPointTop:
;    lda #0
;    sta BrickCollide1_Row
;
;@pointBottomCheck:
;    ;lda #(BallY+1 - POINT_COLLIDE_OFFSET)
;    lda BallY+1
;    sec
;    sbc #POINT_COLLIDE_OFFSET
;    sta TmpY
;
;    jsr GetBallHorizDirection
;    beq @goingLeftBottom
;
;    ;lda #(BallX+1 + EDGE_COLLIDE_OFFSET)
;    lda BallX+1
;    clc
;    adc #EDGE_COLLIDE_OFFSET
;    sta TmpX
;    jmp @checkPointBottom
;
;@goingLeftBottom:
;    ;lda #(BallX+1 - EDGE_COLLIDE_OFFSET)
;    lda BallX+1
;    sec
;    sbc #EDGE_COLLIDE_OFFSET
;    sta TmpX
;
;@checkPointBottom:
;    jsr CheckPointCollide
;    beq @clearPointBottom
;
;    stx BrickCollide2_Row
;    sty BrickCollide2_Col
;
;    lda #$80
;    ora BrickCollide2_Row
;    sta BrickCollide2_Row
;    jmp @checkPointsHoriz
;
;@clearPointBottom:
;    lda #0
;    sta BrickCollide2_Row
;
;@checkPointsHoriz:
;    bit BrickCollide1_Row
;    bpl @noPointTop
;    bit BrickCollide2_Row
;    bpl @noPointBottom
;
;    ; Find collision between left and right points
;    lda BallX+1
;    sta TmpX
;    ;lda #(BallY+1 + EDGE_COLLIDE_OFFSET)
;    lda BallY+1
;    clc
;    adc #EDGE_COLLIDE_OFFSET
;    jsr CheckPointCollide
;
;    stx BrickCollide1_Row
;    sty BrickColIndex_Vert
;
;    lda #$80
;    and BrickCollide1_Row
;    sta BrickRowIndex_Vert
;
;    jmp @actOnCollide
;
;@noPointTop:
;    bit BrickCollide2_Row
;    bpl @noHorizCollide
;;; Just bottom collided
;
;    lda BrickCollide2_Row
;    sta BrickRowIndex_Horiz
;    lda BrickCollide2_Col
;    sta BrickColIndex_Horiz
;
;@noPointBottom:
;;; Just top collided
;    lda BrickCollide1_Row
;    sta BrickRowIndex_Vert
;    lda BrickCollide1_Col
;    sta BrickColIndex_Vert
;    jmp @actOnCollide
;
;@noHorizCollide:
;;; Neither collided
;    lda #0
;    sta BrickRowIndex_Horiz
;    sta BrickColIndex_Horiz
;    jmp @actOnCollide
;
;@actOnCollide:
;    jsr DoVerticalBrickCollide
;    jmp DoHorizontalBrickCollide
;    ;rts

DoVerticalBrickCollide:
    ; FIXME: this math is probably wrong
    ; Determine up or down travel
    ; find the brick coordinate bounds
    ; find the distance into the brick the ball is
    ; add that distance to the opposite direction of the ball
    lda BrickRowIndex_Vert
    and #$7F
    tax

    jsr GetBallVertDirection
    beq @goingUp

    ; going down
    lda BallY+1
    sec
    ;ldx BrickRowIndex_Vert
    sbc Row_Coord_Top, x    ; top brick coord in A
    sta TmpX ; Difference

    sbc Row_Coord_Top, x    ; top brick coord in A
    sbc TmpX
    sta BallY+1

@goingUp:
    ;ldx BrickRowIndex_Vert
    lda Row_Coord_Bot, x
    sec
    sbc BallY+1

    clc
    adc Row_Coord_Bot, x
    sta BallY+1

    jmp BounceVert
    ;rts


DoHorizontalBrickCollide:
    ldx BrickColIndex_Horiz

    jsr GetBallHorizDirection
    beq @goingLeft

    ; FIXME: this math is wrong
    ; going Right
    lda Row_Coord_Left, x
    sec
    sbc BallX+1

    clc
    adc Row_Coord_Left, x
    sta BallX+1

@goingLeft:
    lda BallX+1
    sec
    ; Get the collision point, not the center point of the ball
    sbc #EDGE_COLLIDE_OFFSET
    sta TmpX

    lda Row_Coord_Right, x
    sbc TmpX ; subtract collision point

    clc
    adc Row_Coord_Right, x
    adc #EDGE_COLLIDE_OFFSET
    sta BallX+1

    jmp BounceHoriz
    ;rts

BounceVert:
    lda #$00
    sec
    sbc BallSpeedY
    sta BallSpeedY

    lda #$00
    sbc BallSpeedY+1
    sta BallSpeedY+1
    rts

BounceHoriz:
    lda #$00
    sec
    sbc BallSpeedX
    sta BallSpeedX

    lda #$00
    sbc BallSpeedX+1
    sta BallSpeedX+1
    rts

; Check collision point for a brick
; Point coords in TmpX and TmpY for X and Y,
; respectively
CheckPointCollide:
    lda TmpY
    ; Y >= BOARD_OFFSET_Y, continue
    cmp #BOARD_OFFSET_Y
    bcs :+
    ; Above board
    lda #0
    rts
:
    ; Y < BOARD_HEIGHT + BOARD_OFFSET_Y, continue
    cmp #((BOARD_HEIGHT * 8) + BOARD_OFFSET_Y)
    ;beq :+
    bcc :+
    ; Below board
    lda #0
    rts
:

    lda TmpX
    ; X >= BOARD_OFFSET_X, continue
    cmp #BOARD_OFFSET_X
    bcs :+
    ; Left of board
    lda #0
    rts
:
    ; X <= BOARD_WIDTH + BOARD_OFFSET_X, continue
    cmp #((BOARD_WIDTH * 8) + BOARD_OFFSET_X)
    ;beq :+
    bcc :+
    ; Right of board
    lda #0
    rts
:

    ; Ball is in board area.  Check for brick collision
    jsr PointToTile

    lda Row_Addresses_Low, x
    sta AddressPointer0
    lda Row_Addresses_High, x
    sta AddressPointer0+1

    lda (AddressPointer0), y
    ;bne :+
    ; No tile
    rts

; TODO
ExecuteCollision:
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

;; Check two point's collision and return
;; the proper brick it collided with.
;; Return values in CollisionRow_Ret and CollisionCol_Ret
CheckTwoPointCollision:
    lda PointA_X
    sta TmpX
    lda PointA_Y
    sta TmpY
    jsr CheckPointCollide
    beq :+

    ; Save row/col values for brick's tile
    txa
    ora #$80
    sta CollideRow_A
    sty CollideCol_A
    jmp :++

:   ; no collision
    lda #0
    sta CollideRow_A
    sta CollideCol_A
:

    lda PointB_X
    sta TmpX
    lda PointB_Y
    sta TmpY
    jsr CheckPointCollide
    beq :+

    ; Save row/col values for brick's tile
    txa
    ora #$80
    sta CollideRow_B
    sty CollideCol_B
    jmp :++

:   ; no collision
    lda #0
    sta CollideRow_B
    sta CollideCol_B
:

    lda CollideRow_B
    and #$80
    sta TmpZ

    lda CollideRow_A
    and #$80
    beq @checkOnlyB

    cmp TmpZ
    beq @bothCollide

    ; Return A's collision
    lda CollideRow_A
    ora #$80
    sta CollisionRow_Ret
    lda CollideCol_A
    sta CollisionCol_Ret
    rts

@checkOnlyB:
    lda CollideRow_B
    and #$80
    beq @noCollide

    ; Return B's collision
    lda CollideRow_B
    sta CollisionRow_Ret
    lda CollideCol_B
    sta CollisionCol_Ret
    rts

@bothCollide:
    lda CollideRow_A
    cmp CollideRow_B
    bne @differentBricks
    lda CollideCol_A
    cmp CollideCol_B
    bne @differentBricks

    ; Both the same brick, return A's collision
    lda CollideRow_A
    sta CollisionRow_Ret
    lda CollideCol_A
    sta CollisionCol_Ret
    rts

@noCollide:
    ; Nothing collided, clear return values
    lda #0
    sta CollisionRow_Ret
    sta CollisionCol_Ret
    rts

@differentBricks:
    ;; Return AB's collision
    lda PointA_X
    cmp PointB_X
    beq @horizontal

    ; Vertical
    lda PointA_Y
    sta TmpY

    lda PointA_X
    clc
    adc #POINT_COLLIDE_OFFSET
    sta TmpX
    jmp @thirdPointCoords

@horizontal:
    lda PointA_X
    sta TmpX

    lda PointA_Y
    clc
    adc #POINT_COLLIDE_OFFSET
    sta TmpX

@thirdPointCoords:
    jsr PointToTile

    txa
    ora #$80
    sta CollisionRow_Ret
    sty CollisionCol_Ret
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

Row_Addresses_Low:
.repeat BOARD_HEIGHT, i
    .byte .lobyte(CurrentMap+(i*BOARD_WIDTH))
.endrepeat

Row_Addresses_High:
.repeat BOARD_HEIGHT, i
    .byte .hibyte(CurrentMap+(i*BOARD_WIDTH))
.endrepeat

; Lookup tables for tile pixel bounds
Row_Coord_Top:
.repeat BOARD_HEIGHT, i
    .byte (BOARD_OFFSET_Y + (8 * i))
.endrepeat

Row_Coord_Bot:
.repeat BOARD_HEIGHT, i
    .byte (BOARD_OFFSET_Y + (8 * i)) + 7
.endrepeat

Row_Coord_Left:
.repeat BOARD_WIDTH, i
    .byte (BOARD_OFFSET_X + (8 * i))
.endrepeat

Row_Coord_Right:
.repeat BOARD_WIDTH, i
    .byte (BOARD_OFFSET_X + (8 * i)) + 7
.endrepeat
