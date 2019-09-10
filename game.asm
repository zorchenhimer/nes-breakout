; asmsyntax=ca65

.include "game_ram.asm"

.importzp child_NUMBER_OF_MAPS

BALL_UP = $80
BALL_DOWN = $00
BALL_LEFT = $00
BALL_RIGHT = $40

BOUNCE_STEP = $18

SPRITE_ID_BALL = $0A
SPRITE_ID_PADDLE_MID = $09
SPRITE_ID_PADDLE_SIDE = $08

BOOST_VALUE = $F0
MAX_BOOST_POOL = 2

Initial_Ball_Speed_WHOLE = 1
Initial_Ball_Speed_FRACT = 0

Initial_Ball_Direction = BALL_DOWN | BALL_RIGHT

Initial_Paddle_Speed_WHOLE = 2
Initial_Paddle_Speed_FRACT = 0

Initial_Ball_X = 50 ; 200
Initial_Ball_Y = 154 ; $C0

Paddle_Speed_Slow_WHOLE = 1
Paddle_Speed_Slow_FRACT = 0

Paddle_Speed_Fast_WHOLE = 3
Paddle_Speed_Fast_FRACT = 128

Initial_Paddle_X = 128
Initial_Paddle_Y = 208

WALL_RIGHT = $F5
WALL_LEFT = $0A
WALL_TOP = $11
WALL_BOTTOM = $DD

BALL_SPRITE_OFFSET_X = 2
BALL_SPRITE_OFFSET_Y = 3

EDGE_COLLIDE_OFFSET = 3
POINT_COLLIDE_OFFSET = 1

;START_MAP = 4

GRAVITY_VALUE = $04

; For collision
PADDLE_VERT_OFFSET = 3
PADDLE_VERT_COLLIDE_OFFSET = EDGE_COLLIDE_OFFSET + PADDLE_VERT_OFFSET
PADDLE_CENTER_WIDTH = 11

; For drawing
PADDLE_SPRITE_OFFSET_X = 3
PADDLE_SPRITE_OFFSET_Y = 3

PADDLE_WALL_LEFT = $14
PADDLE_WALL_RIGHT = $EC

; These are RAM addresses
Paddle_Sprite_Start = $0208
Paddle_Sprite_X = Paddle_Sprite_Start + 3
Paddle_Sprite_Y = Paddle_Sprite_Start + 0
Paddle_Sprite_Tile = Paddle_Sprite_Start + 1
Paddle_Sprite_Attr = Paddle_Sprite_Start + 2

Pal_Game:
    .byte $0F, $0A, $1A, $2A

Pal_GameSprites:
    .byte $0F, $00, $10, $20

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
    jsr FillNametable0
    jsr ClearAttrTable0

    lda #1
    jsr LoadChrData

    jsr ClearSprites

    jsr Clear_NonGlobalRam
    jsr Clear_ExtendedRam

    ; Tile
    lda #SPRITE_ID_BALL
    sta Sprites+5

    ; Attributes
    lda #0
    sta Sprites+6
    sta Paddle_Sprite_Attr
    sta Paddle_Sprite_Attr+4

    lda #$40
    sta Paddle_Sprite_Attr+8

    lda #SPRITE_ID_PADDLE_MID
    sta Paddle_Sprite_Tile

    lda #SPRITE_ID_PADDLE_SIDE
    sta Paddle_Sprite_Tile+4
    sta Paddle_Sprite_Tile+8

    lda #MAX_BOOST_POOL
    sta BoostPool

    lda #16
    sta Sprites+(4*5)+0
    sta Sprites+(4*5)+3

    lda #$0D
    sta Sprites+(4*5)+1

    lda #0
    sta Sprites+(4*5)+2

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

    jsr ResetBall

    lda #0
    sta PaddleX
    sta PaddleY
    sta ChildId

    lda #<Row_Coord_Top
    sta Address_RowCoordTop
    lda #>Row_Coord_Top
    sta Address_RowCoordTop+1

    lda #<Row_Coord_Bot
    sta Address_RowCoordBot
    lda #>Row_Coord_Bot
    sta Address_RowCoordBot+1

    lda #<Row_Coord_Left
    sta Address_RowCoordLeft
    lda #>Row_Coord_Left
    sta Address_RowCoordLeft+1

    lda #<Row_Coord_Right
    sta Address_RowCoordRight
    lda #>Row_Coord_Right
    sta Address_RowCoordRight+1

    lda #BOARD_OFFSET_Y
    sta game_BoardOffsetY
    lda #BOARD_OFFSET_X
    sta game_BoardOffsetX

    lda #BOARD_WIDTH
    sta game_BoardWidth
    lda #BOARD_HEIGHT
    sta game_BoardHeight

    lda #PADDLE_WALL_LEFT
    sta game_PaddleWallLeft
    lda #PADDLE_WALL_RIGHT
    sta game_PaddleWallRight

    lda #Initial_Paddle_X
    sta PaddleX+1
    lda #Initial_Paddle_Y
    sta PaddleY+1

    lda #Initial_Paddle_Speed_FRACT
    sta PaddleSpeed
    lda #Initial_Paddle_Speed_WHOLE
    sta PaddleSpeed+1

    jsr UpdatePaddleSprite

    lda CurrentBoard
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

Frame_Game:
    jsr ReadControllers

    lda #BUTTON_SELECT
    jsr ButtonPressedP1
    beq :+
    jsr ResetBall
:

    lda #BUTTON_A
    jsr ButtonPressedP1
    beq :+
    jsr BoostTheBall
:

    jsr UpdateBallCoords
    jsr UpdatePaddleCoords

    jsr CheckWallCollide
    jsr CheckBrickCollide
    jsr CheckPaddleCollide

    jsr UpdateBallSprite
    jsr UpdatePaddleSprite

    jsr UpdateBoostSprite

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

    ; Destroy any bricks that need destroying
    lda HorizDestroy
    beq :+
    bit $2002
    sta $2006
    lda HorizDestroy+1
    sta $2006

    lda #0
    sta $2007
    sta $2007
    sta HorizDestroy
:
    lda VertDestroy
    beq :+
    bit $2002
    sta $2006
    lda VertDestroy+1
    sta $2006

    lda #0
    sta $2007
    sta $2007
    sta VertDestroy
:

    lda #0
    sta $2005
    sta $2005

    lda #%10011000
    sta $2000

    dec Sleeping
    rti

game_LoadChild:
    lda ChildId
    pha

    inc ChildId
    lda ChildId
    cmp #child_NUMBER_OF_MAPS
    bcc :+
    lda #0
    sta ChildId
:
    pla
    jmp LoadChildMap

BoostTheBall:
    lda BoostPool
    bne :+
    rts

:   dec BoostPool
    bit BallDirection
    bpl @down

    ; going up
    lda BallSpeedY
    clc
    adc #BOOST_VALUE
    sta BallSpeedY

    lda BallSpeedY+1
    adc #0
    sta BallSpeedY+1
    rts

@down:
    lda BallSpeedY
    sec
    sbc #BOOST_VALUE
    sta BallSpeedY
    lda BallSpeedY+1
    sbc #0
    sta BallSpeedY+1
    bmi :+
    rts

:
    ; handle underflow
    lda #0
    sec
    sbc BallSpeedY
    sta BallSpeedY

    lda BallSpeedY+1
    sbc #0
    sta BallSpeedY+1

    lda BallDirection
    and #$40
    sta BallDirection
    rts

UpdateBoostSprite:
    lda BoostPool
    beq @empty

    clc
    adc #$0A
    sta Sprites+(4*5)+1
    rts

@empty:
    lda #0
    sta Sprites+(4*5)+1
    rts

ResetBall:
    lda #$00
    sta BallX
    sta BallY

    lda #Initial_Ball_Direction
    sta BallDirection

    lda #Initial_Ball_X
    sta BallX+1
    lda #Initial_Ball_Y
    sta BallY+1

    lda #Initial_Ball_Speed_FRACT
    sta BallSpeedY
    sta BallSpeedX

    lda #Initial_Ball_Speed_WHOLE
    sta BallSpeedY+1
    sta BallSpeedX+1
    rts

; Read the button inputs and update the paddle coords accordingly
UpdatePaddleCoords:
    lda #Initial_Paddle_Speed_FRACT
    sta PaddleSpeed
    lda #Initial_Paddle_Speed_WHOLE
    sta PaddleSpeed+1

    ; Do not change speed if both A and B are pressed
    lda #BUTTON_A | BUTTON_B
    and controller1
    cmp #BUTTON_A | BUTTON_B
    beq @skipAB

    ; Go faster with A pressed
    lda #BUTTON_A
    and controller1
    beq :+
    lda #Paddle_Speed_Fast_FRACT
    sta PaddleSpeed
    lda #Paddle_Speed_Fast_WHOLE
    sta PaddleSpeed+1
    jmp @skipAB
:

    ; Go slower with B pressed
    lda #BUTTON_B
    and controller1
    beq :+
    lda #Paddle_Speed_Slow_FRACT
    sta PaddleSpeed
    lda #Paddle_Speed_Slow_WHOLE
    sta PaddleSpeed+1
:

@skipAB:
    ; Left bounds
    lda PaddleX+1
    cmp game_PaddleWallLeft
    bcc :+

    lda #BUTTON_LEFT
    and controller1
    beq :+
    ; Move left
    lda PaddleX
    sec
    sbc PaddleSpeed
    sta PaddleX

    lda PaddleX+1
    sbc PaddleSpeed+1
    sta PaddleX+1
:
    ; snap to wall
    lda PaddleX+1
    cmp game_PaddleWallLeft
    bcs :+
    lda game_PaddleWallLeft
    sec
    sbc #1
    sta PaddleX+1
:

    ; Right bounds
    lda PaddleX+1
    cmp game_PaddleWallRight
    bcs :+

    lda #BUTTON_RIGHT
    and controller1
    beq :+
    ; Move right
    lda PaddleX
    clc
    adc PaddleSpeed
    sta PaddleX

    lda PaddleX+1
    adc PaddleSpeed+1
    sta PaddleX+1
:

    ; snap to wall
    lda PaddleX+1
    cmp game_PaddleWallRight
    bcc :+
    lda game_PaddleWallRight
    sta PaddleX+1
:
    rts

ApplyGravity:
    bit BallDirection
    bpl @down
    ;up

    lda BallSpeedY
    sec
    sbc #GRAVITY_VALUE
    sta BallSpeedY

    lda BallSpeedY+1
    sbc #0
    sta BallSpeedY+1
    bpl :+

    ; wrap around
    lda #0
    sec
    sbc BallSpeedY
    sta BallSpeedY
    lda #0
    sbc BallSpeedY+1
    sta BallSpeedY+1

    lda BallDirection
    and #$40
    sta BallDirection
:
    rts

@down:
    lda BallSpeedY
    clc
    adc #GRAVITY_VALUE
    sta BallSpeedY

    lda BallSpeedY+1
    adc #0
    sta BallSpeedY+1

    cmp #3
    bcc @nope
    lda #$02
    sta BallSpeedY+1
    lda #0
    sta BallSpeedY
@nope:
    rts

; Read BallX and BallY coords and translate
; them to sprite coords
UpdateBallCoords:

    jsr ApplyGravity ;lol

    ; Update coords in memory using the speeds
    bit BallDirection
    bvs @right
    ; left
    lda BallX
    sec
    sbc BallSpeedX
    sta BallX

    lda BallX+1
    sbc BallSpeedX+1
    sta BallX+1
    jmp @vertical

@right:
    lda BallX
    clc
    adc BallSpeedX
    sta BallX

    lda BallX+1
    adc BallSpeedX+1
    sta BallX+1

@vertical:
    bit BallDirection
    bmi @up
    ; down
    lda BallY
    clc
    adc BallSpeedY
    sta BallY

    lda BallY+1
    adc BallSpeedY+1
    sta BallY+1
    rts

@up:
    lda BallY
    sec
    sbc BallSpeedY
    sta BallY

    lda BallY+1
    sbc BallSpeedY+1
    sta BallY+1
    rts

UpdatePaddleSprite:
    ; Center sprite
    lda PaddleX+1
    sec
    sbc #PADDLE_SPRITE_OFFSET_X
    sta TmpX
    sta Paddle_Sprite_X

    lda PaddleY+1
    sec
    sbc #PADDLE_SPRITE_OFFSET_Y
    sta TmpY
    sta Paddle_Sprite_Y

    ; Left sprite
    lda TmpY
    sta Paddle_Sprite_Y+4

    lda TmpX
    sec
    sbc #8
    sta Paddle_Sprite_X+4

    ; Right sprite
    lda TmpY
    sta Paddle_Sprite_Y+8

    lda TmpX
    clc
    adc #7
    sta Paddle_Sprite_X+8

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
    sbc game_BoardOffsetY
    ; divide by 8
    lsr a
    lsr a
    lsr a
    ; Lookup that row's pointer
    tax

    lda TmpX
    sec
    ; Subtract offset
    sbc game_BoardOffsetX
    ; divide by 8
    lsr a
    lsr a
    lsr a
    ; "Store" it
    tay
    rts

; TODO: remove constants from this
CheckWallCollide:
    bit BallDirection
    bpl @goingDown
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
    ; TODO: kill wall
    jmp ResetBall

@bounceVert:
    jsr BounceVert

@checkHoriz:
    bit BallDirection
    bvs @goingRight
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

CheckPaddleCollide:
    bit BallDirection
    bpl :+
    rts ; ball is traveling up
:

    lda BallY+1
    clc
    adc #PADDLE_VERT_OFFSET
    cmp PaddleY+1
    bcs :+
    rts ; Ball too high
:

    lda BallY+1
    sec
    sbc #PADDLE_VERT_OFFSET
    ;adc #PADDLE_VERT_OFFSET + EDGE_COLLIDE_OFFSET
    cmp PaddleY+1
    beq :+
    bcc :+
    rts ; Ball is too low
:

    lda PaddleX+1
    clc
    adc #PADDLE_CENTER_WIDTH
    cmp BallX+1
    bcs :+
    ;rts ; Ball is to the right of paddle
    jmp CheckPaddleHorizCollide
:
    lda PaddleX+1
    sec
    sbc #PADDLE_CENTER_WIDTH
    cmp BallX+1
    beq :+
    bcc :+
    ;rts ; Ball is to the left of paddle
    jmp CheckPaddleHorizCollide
:
    inc BoostPool
    lda BoostPool
    cmp #MAX_BOOST_POOL
    bcc :+
    lda #MAX_BOOST_POOL
    sta BoostPool
:
    jsr UpdateBallAngle
    jmp BounceVert

UpdateBallAngle:
    ; get the horizontal distance between the center points of the
    ; ball and paddle as a positive number.
    lda #0
    sta IdxA

    lda BallX+1
    sec
    sbc PaddleX+1
    bpl :+

    ; make value positive (0 - val)
    sec
    sta TmpX
    lda #0
    sbc TmpX
    inc IdxA
:
    bne @offCenter
    ; dead center

    lda #0
    sta BallSpeedX
    sta BallSpeedX+1
    sta BallSpeedY

    lda #2
    sta BallSpeedY+1
    rts

@offCenter:
    asl a   ; 4x for index into table of word pairs
    asl a
    tax

    lda Bounce_Speed, x
    pha
    lda Bounce_Speed+1, x
    pha

    lda Bounce_Speed+2, x
    pha
    lda Bounce_Speed+3, x
    pha

    ; IdxA - if zero, ball on right; if one, ball on left
    lda IdxA
    bne @left
    ; ball on right

    pla
    sta BallSpeedY+1
    pla
    sta BallSpeedY

    pla
    sta BallSpeedX+1
    pla
    sta BallSpeedX

    lda BallDirection
    ora #$40
    sta BallDirection
    rts

@left:
    pla
    sta BallSpeedY+1
    pla
    sta BallSpeedY

    pla
    sta BallSpeedX+1
    pla
    sta BallSpeedX

    lda BallDirection
    and #$80
    sta BallDirection
    rts

; TODO: remove constants from this too? (variable width paddle)
CheckPaddleHorizCollide:
    lda BallX+1
    cmp PaddleX+1
    bcc @onLeft

    ; on right
    bit BallDirection
    bvc :+
    ; bit set, traveling right; don't collide
    rts
:

    lda PaddleX+1
    clc
    adc #PADDLE_CENTER_WIDTH + EDGE_COLLIDE_OFFSET
    cmp BallX+1
    bcs :+
    rts ; ball is to the right of paddle
:
    jmp BounceHoriz

@onLeft:
    bit BallDirection
    bvs :+
    ; bit clear, traveling left; don't collide
    rts
:
    lda PaddleX+1
    sec
    sbc #PADDLE_CENTER_WIDTH + EDGE_COLLIDE_OFFSET + 1
    cmp BallX+1
    bcc :+
    rts ; ball is to the right of paddle
:
    jmp BounceHoriz
    ;rts

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
    bit BallDirection
    bmi @ballGoingUp

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

    ; something collided, check for adjacent brick
    lda CollisionRow_Ret
    and #$7F
    tax
    ldy CollisionCol_Ret

    ; get direction
    bit BallDirection
    bmi :+
    ; going down, check for top brick
    dex
    bpl :++
    ;; Underflow
    jmp @vertDoCollide
:
    ; going up, check for bottom brick
    inx
    cpx game_BoardHeight
    beq @vertDoCollide
:

    lda Row_Addresses_Low, x
    sta AddressPointer0
    lda Row_Addresses_High, x
    sta AddressPointer0+1
    lda (AddressPointer0), y
    bne @noVertCollide ; there is a brick, do not collide

@vertDoCollide:
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

    bit BallDirection
    bvc @ballGoingLeft
    ;beq @ballGoingLeft
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

    ; something collided, check for adjacent brick
    lda CollisionRow_Ret
    and #$7F
    tax
    ldy CollisionCol_Ret

    ; get direction
    bit BallDirection
    bvc :+
    ;beq :+
    ; gong right, check for left brick
    dey
    bpl :++
    jmp @horizDoCollide
:
    ; going left, check for right brick
    iny
    cpy game_BoardWidth
    beq @horizDoCollide
:

    lda Row_Addresses_Low, x
    sta AddressPointer0
    lda Row_Addresses_High, x
    sta AddressPointer0+1

    lda (AddressPointer0), y
    bne @noHorizCollide ; there is a brick, do not collide

@horizDoCollide:
    ; Something collided, store it
    lda CollisionRow_Ret
    sta BrickRowIndex_Horiz
    lda CollisionCol_Ret
    sta BrickColIndex_Horiz
    jmp @doCollisions
    ;jmp @actOnVert

@noHorizCollide:
    lda #0
    sta BrickRowIndex_Horiz
    sta BrickColIndex_Horiz

@doCollisions:

    bit BrickRowIndex_Vert
    bpl :+
    jsr DoVerticalBrickCollide
:

    bit BrickRowIndex_Horiz
    bpl :+
    jsr DoHorizontalBrickCollide
:
    rts

game_GetAddressForChildBrick:
    lda CurrentBoard
    and #$7F
    asl a
    tax

    ; Get the start address of the map
    lda Child_Map_Addresses, x
    sta BrickAddress
    lda Child_Map_Addresses+1, x
    sta BrickAddress+1

    ; Get the number of bytes to add to the
    ; address for the current row.
    ldx BrickRow
    lda data_Mult12, x

    clc
    adc BrickAddress
    adc BrickCol
    sta BrickAddress

    bcc :+
    inc BrickAddress+1
:

    ; Corret address to point to first
    ; byte of brick
    ldy #0
    lda (BrickAddress), y
    bpl :+
    ; looking at  second tile
    lda BrickAddress
    ; If low byte is $00, both bytes need
    ; to be dec'd
    beq @decBoth
    dec BrickAddress
    jmp :+
@decBoth:
    dec BrickAddress
    dec BrickAddress+1
:

    lda BrickRow
    asl a
    tax

    lda Index_PpuChildBrickRows+1, x
    sta BrickPpuAddress+1
    lda Index_PpuChildBrickRows, x

    clc
    adc BrickCol
    sta BrickPpuAddress

    bcc :+
    inc BrickPpuAddress+1
:
    rts

; Take the brick X and Y (in TmpX and TmpY, respectively)
; and return the start address for that brick in AddressPointer0
GetAddressesForBrick:
    bit CurrentBoard
    bmi game_GetAddressForChildBrick

    ; Find the first byte of brick
    ldx BrickRow
    lda Row_Addresses_Low, x
    sta BrickAddress
    lda Row_Addresses_High, x
    sta BrickAddress+1

    ; Correct for brick's second byte
    ; (needs to be pointing to the first byte)
    ; FIXME: will break if BrickAddress is $0500
    ldy BrickCol
    lda (BrickAddress), y
    bpl :+
    dec BrickCol
:

    ; Add column onto brick address
    lda BrickCol
    clc
    adc BrickAddress
    sta BrickAddress
    lda BrickAddress+1
    adc #0
    sta BrickAddress+1

    ; Figure out the PPU address for a brick
    lda BrickRow
    asl a
    tax

    lda Index_PpuBrickRows, x
    sta BrickPpuAddress
    lda Index_PpuBrickRows+1, x

    clc
    adc BrickCol
    sta BrickPpuAddress

    ; handle overflow
    bcc :+
    inc BrickPpuAddress+1
:

    rts

DoVerticalBrickCollide:
    ; Determine up or down travel
    ; find the brick coordinate bounds
    ; find the distance into the brick the ball is
    ; add that distance to the opposite direction of the ball
    lda BrickRowIndex_Vert
    and #$7F
    pha

    sta BrickRow
    lda BrickColIndex_Vert
    sta BrickCol

    jsr DoBrickAction
    beq :+
    pla
    rts ; DoBrickAction returns 1 if
        ; everything else should be skipped.
:       ; "everything" is to be determined.

    pla
    tay

    bit BallDirection
    bmi @goingUp

    ; going down
    ; distance into brick = BallY - Wall
    lda BallY+1
    sec
    sbc (Address_RowCoordTop), y    ; top brick coord in A
    sta TmpX ; Difference

    lda (Address_RowCoordTop), y    ; top brick coord in A
    sec
    sbc TmpX
    sta BallY+1
    jmp BounceVert

@goingUp:
    ; distance into brick = Wall - BallY
    lda (Address_RowCoordBot), y
    sec
    sbc BallY+1

    clc
    adc (Address_RowCoordBot), y
    sta BallY+1

    jmp BounceVert

DoHorizontalBrickCollide:
    lda BrickRowIndex_Horiz
    and #$7F
    sta BrickRow
    lda BrickColIndex_Horiz
    sta BrickCol

    jsr DoBrickAction
    beq :+
    rts ; DoBrickAction returns 1 if
        ; everything else should be skipped.
        ; "everything" is to be determined.
:

    ldy BrickColIndex_Horiz

    bit BallDirection
    bvc @goingLeft

    ; going Right
    ; distance into wall = (BallX + edge offset) - LeftWall
    lda BallX+1
    sec
    sbc (Address_RowCoordLeft), y
    sta TmpX    ; distance

    lda (Address_RowCoordLeft), y
    sec
    sbc TmpX
    sta BallX+1
    jmp BounceHoriz

@goingLeft:
    ; distance into wall = RightWall - BallX - EdgeOffset
    lda (Address_RowCoordRight), y
    sbc BallX+1 ; subtract collision point

    clc
    adc (Address_RowCoordRight), y
    sta BallX+1

    jmp BounceHoriz

BounceVert:
    ; Bit 7 is vertical
    lda BallDirection
    eor #$80
    sta BallDirection
    rts

BounceHoriz:
    ; Bit 6 is horizontal
    lda BallDirection
    eor #$40
    sta BallDirection
    rts

; Check collision point for a brick
; Point coords in TmpX and TmpY for X and Y,
; respectively
CheckPointCollide:
    lda TmpY
    ; Y >= BOARD_OFFSET_Y, continue
    cmp game_BoardOffsetY
    bcs :+
    ; Above board
    lda #0
    rts
:
    ; Y < (BOARD_HEIGHT * 8px) + BOARD_OFFSET_Y, continue
    lda game_BoardHeight
    asl a
    asl a
    asl a
    clc
    adc game_BoardOffsetY
    sta TmpZ

    lda TmpY
    ;cmp #((BOARD_HEIGHT * 8) + BOARD_OFFSET_Y)
    cmp TmpZ
    bcc :+
    ; Below board
    lda #0
    rts
:

    lda TmpX
    ; X >= BOARD_OFFSET_X, continue
    cmp game_BoardOffsetX
    bcs :+
    ; Left of board
    lda #0
    rts
:
    ; X <= (BOARD_WIDTH * 8px) + BOARD_OFFSET_X, continue
    lda game_BoardWidth
    asl a
    asl a
    asl a
    clc
    adc game_BoardOffsetX
    sta TmpZ

    lda TmpX
    cmp TmpZ
    ;cmp #((BOARD_WIDTH * 8) + BOARD_OFFSET_X)
    bcc :+
    ; Right of board
    lda #0
    rts
:

    ; Ball is in board area.  Check for brick collision
    jsr PointToTile

    bit CurrentBoard
    bmi :+
    ; Main board
    lda Row_Addresses_Low, x
    sta AddressPointer0
    lda Row_Addresses_High, x
    sta AddressPointer0+1
    lda (AddressPointer0), y
    rts
:
    ; Child board
    txa
    pha
    lda CurrentBoard
    asl a
    tax

    ; Pointer to start of board
    lda Child_Map_Addresses, x
    sta AddressPointer0
    lda Child_Map_Addresses+1, x
    sta AddressPointer0+1

    ; Increment pointer to start of row
    pla
    tax
    lda data_Mult12, x
    clc
    adc AddressPointer0
    sta AddressPointer0

    bcc :+
    inc AddressPointer0+1
:

    lda (AddressPointer0), y
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

    ; Lookup ppu address for row
    lda TmpX
    asl a
    tax
    bit $2002
    lda Index_PpuBrickRows+1, x
    sta $2006
    lda Index_PpuBrickRows+0, x
    sta $2006

    ; Draw it
    jsr game_DrawRow

    ; Are we done?
    inc TmpX
    lda TmpX
    cmp game_BoardHeight
    bne @loop
    rts


; Expects the PPU address to already be set.
game_DrawRow:
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
    cpy game_BoardWidth
    bne @loop
    rts

@noTile:
    lda #NoTileID
    sta $2007

    iny
    cpy game_BoardWidth
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
    sta TmpY

@thirdPointCoords:
    jsr PointToTile

    txa
    ora #$80
    sta CollisionRow_Ret
    sty CollisionCol_Ret
    rts

; This will handle any and all brick actions for
; a given collision.  The ball is not modified here.
DoBrickAction:
    jsr GetAddressesForBrick
    lda BrickAddress
    bne :+
    lda #1
    rts
:

    ldy #0
    lda (BrickAddress), y
    and #$0F

    ; subtract one to get real index
    ; into table (value of $00 is "no brick")
    sec
    sbc #1

    asl a
    tax

    lda BrickActions, x
    sta AddressPointer0
    lda BrickActions+1, x
    sta AddressPointer0+1

    jmp (AddressPointer0)

game_ActionHealth:
    ldy #1
    lda (BrickAddress), y
    and #$7F ; mask off byte identifier
    bne :+
    ; value is zero, remove brick
    jmp game_RemoveBrick
:
    ; value is not zero, dec and do not remove.
    sec
    sbc #1
    ora #$80    ; set the top bit. this is the second byte identifier.
    sta (BrickAddress), y

    lda #0
    rts

game_ActionSpawn:
    ldy #1
    lda (BrickAddress), y
    and #$7F
    sta ChildId    ; Child board index.  Either in RAM or ROM.

    ldy #0
    lda (BrickAddress), y
    and #$30
    bne @drawChildMap

    ; Set child board as loaded
    lda (BrickAddress), y
    ora #$30
    sta (BrickAddress), y

    ; load map
    jsr game_LoadChild

    ; Update ChildID in the brick
    ldy #1
    lda (BrickAddress), y
    ora ChildId
    sta (BrickAddress), y

    lda ChildId
    ora #$80
    sta CurrentBoard

@drawChildMap:
    ; Map is loaded, draw it

    NMI_Disable
    jsr WaitForNMI

    ; Turn off BG and sprites
    lda #$00
    sta $2001

    lda #0
    jsr FillNametable0
    jsr ClearAttrTable0

    ldx ChildId

    ; Get the start address of the child map
    ; in RAM.
    lda Child_Map_Addresses, x
    sta AddressPointer0
    lda Child_Map_Addresses+1, x
    sta AddressPointer0+1

    lda #CHILD_BOARD_HEIGHT
    sta game_BoardHeight
    lda #CHILD_BOARD_WIDTH
    sta game_BoardWidth

    lda #CHILD_OFFSET_Y
    sta game_BoardOffsetY
    lda #CHILD_OFFSET_X
    sta game_BoardOffsetX

    lda #<Child_Row_Coord_Top
    sta Address_RowCoordTop
    lda #>Child_Row_Coord_Top
    sta Address_RowCoordTop+1

    lda #<Child_Row_Coord_Bot
    sta Address_RowCoordBot
    lda #>Child_Row_Coord_Bot
    sta Address_RowCoordBot+1

    lda #<Child_Row_Coord_Left
    sta Address_RowCoordLeft
    lda #>Child_Row_Coord_Left
    sta Address_RowCoordLeft+1

    lda #<Child_Row_Coord_Right
    sta Address_RowCoordRight
    lda #>Child_Row_Coord_Right
    sta Address_RowCoordRight+1

    lda #0
    sta TmpX

@rowLoop:
    ; Get and write the PPU address
    lda TmpX
    asl a
    tax
    bit $2002
    lda Index_PpuChildBrickRows+1, x
    sta $2006
    lda Index_PpuChildBrickRows+0, x
    sta $2006

    jsr game_DrawRow

    ; Increment address to next row
    lda AddressPointer0
    clc
    adc game_BoardWidth
    sta AddressPointer0

    lda #0
    adc AddressPointer0+1
    sta AddressPointer0+1

    inc TmpX
    lda TmpX
    cmp game_BoardHeight
    bne @rowLoop

    jsr ResetBall

    NMI_Set NMI_Game

    lda #%00011110
    sta $2001

    lda #1
    rts

game_ActionItemDrop:
    ; TODO: item drops
    jmp game_RemoveBrick

game_RemoveBrick:
    ; Remove from screen
    lda BrickPpuAddress
    sta VertDestroy
    lda BrickPpuAddress+1
    sta VertDestroy+1

    ; Remove from RAM
    lda #0
    ldy #0
    sta (BrickAddress), y
    iny
    sta (BrickAddress), y

    lda #0
    rts

NoTileID = $00
Index_TileDefs:
    .byte $02, $03  ; Health
    .byte $04, $05  ; Spawn
    .byte $06, $07  ; Item drops

BrickActions:
    .word game_ActionHealth
    .word game_ActionSpawn
    .word game_ActionItemDrop

Index_PpuBrickRows:
.repeat BOARD_HEIGHT, i
    .word $2000 + (((BOARD_OFFSET_Y/8) * 32) + (BOARD_OFFSET_X/8)) + i * 32
.endrepeat

Index_PpuChildBrickRows:
.repeat CHILD_BOARD_HEIGHT, i
    .word $2000 + (((CHILD_OFFSET_Y/8) * 32) + (CHILD_OFFSET_X/8)) + i * 32
.endrepeat

; Row Addresses for main map
Row_Addresses_Low:
.repeat BOARD_HEIGHT, i
    .byte .lobyte(CurrentMap+(i*BOARD_WIDTH))
.endrepeat

Row_Addresses_High:
.repeat BOARD_HEIGHT, i
    .byte .hibyte(CurrentMap+(i*BOARD_WIDTH))
.endrepeat

; Lookup tables for tile pixel bounds (main map)
Row_Coord_Top:
.repeat BOARD_HEIGHT, i
    .byte (BOARD_OFFSET_Y + (8 * i)) - EDGE_COLLIDE_OFFSET
.endrepeat

Row_Coord_Bot:
.repeat BOARD_HEIGHT, i
    .byte (BOARD_OFFSET_Y + (8 * i)) + 7 + EDGE_COLLIDE_OFFSET
.endrepeat

Row_Coord_Left:
.repeat BOARD_WIDTH, i
    .byte (BOARD_OFFSET_X + (8 * i)) - EDGE_COLLIDE_OFFSET
.endrepeat

Row_Coord_Right:
.repeat BOARD_WIDTH, i
    .byte (BOARD_OFFSET_X + (8 * i)) + 7 + EDGE_COLLIDE_OFFSET
.endrepeat

; Lookup tables for tile pixel bounds (child maps)
Child_Row_Coord_Top:
.repeat CHILD_BOARD_HEIGHT, i
    .byte (CHILD_OFFSET_Y + (8 * i)) - EDGE_COLLIDE_OFFSET
.endrepeat

Child_Row_Coord_Bot:
.repeat CHILD_BOARD_HEIGHT, i
    .byte (CHILD_OFFSET_Y + (8 * i)) + 7 + EDGE_COLLIDE_OFFSET
.endrepeat

Child_Row_Coord_Left:
.repeat CHILD_BOARD_WIDTH, i
    .byte (CHILD_OFFSET_X + (8 * i)) - EDGE_COLLIDE_OFFSET
.endrepeat

Child_Row_Coord_Right:
.repeat CHILD_BOARD_WIDTH, i
    .byte (CHILD_OFFSET_X + (8 * i)) + 7 + EDGE_COLLIDE_OFFSET
.endrepeat

Bounce_Speed:
.repeat 12, i
    .word BOUNCE_STEP * i
    .word ($0200 - (BOUNCE_STEP * i))
.endrepeat
