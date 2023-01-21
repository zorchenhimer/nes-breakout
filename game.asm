; asmsyntax=ca65

.include "game_ram.asm"

.importzp child_NUMBER_OF_MAPS

; Word value.  Frames active.
PU_GRAVITY_DURATION = 600

Death_Height = 200
Death_Offset = 4    ; negative offset from ball center

BALL_UP = $80
BALL_DOWN = $00
BALL_LEFT = $00
BALL_RIGHT = $40

BOUNCE_STEP = $18

SPRITE_ID_BALL = $0A
SPRITE_ID_PADDLE_MID = $09
SPRITE_ID_PADDLE_SIDE = $08

BOOST_VALUE = $F0
MAX_BOOST_POOL = 3

Initial_Ball_Speed_WHOLE = 1
Initial_Ball_Speed_FRACT = 0

Initial_Ball_Direction = BALL_UP | BALL_RIGHT

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

Child_Paddle_Y = 184

WALL_RIGHT = $F5
WALL_LEFT = $0A
WALL_TOP = $11
WALL_BOTTOM = $EA

CHILD_WALL_RIGHT = WALL_RIGHT - (8 * 5)
CHILD_WALL_LEFT = WALL_LEFT + (8 * 5)
CHILD_WALL_TOP = WALL_TOP + (8 * 2)
CHILD_WALL_BOTTOM = WALL_BOTTOM - (8 * 4)

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

PADDLE_WALL_LEFT = WALL_LEFT + 10 ;$14
PADDLE_WALL_RIGHT = WALL_RIGHT - 9 ;$EC

CHILD_PADDLE_WALL_LEFT = CHILD_WALL_LEFT + 10 ;$14
CHILD_PADDLE_WALL_RIGHT = CHILD_WALL_RIGHT - 9 ;$EC

; These are RAM addresses
Paddle_Sprite_Start = $0208
Paddle_Sprite_X = Paddle_Sprite_Start + 3
Paddle_Sprite_Y = Paddle_Sprite_Start + 0
Paddle_Sprite_Tile = Paddle_Sprite_Start + 1
Paddle_Sprite_Attr = Paddle_Sprite_Start + 2

Pal_Game:
    .byte $0F, $01, $11, $21

Pal_GameSprites:
    .byte $0F, $00, $10, $20
    .byte $0F, $16, $16, $2A

Init_Game:
    .NMI_Disable

    ; Disable drawing BG and sprites
    .Disable_Drawing

    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    ; Load up a palette
.repeat 4, i
    lda Pal_Game+i
    sta PaletteBuffer+i
.endrepeat

    lda #$3F
    sta $2006
    lda #$10
    sta $2006

    ; Load up another palette
.repeat 8, i
    lda Pal_GameSprites+i
    sta PaletteBufferSprites+i
.endrepeat

    lda #0
    ;jsr FillNametable1
    jsr ClearAttrTable0

    lda #ChrData::Game
    jsr LoadChrData

    lda #ChrData::Game2
    jsr LoadChrData

    lda #$00
    jsr Waves_LoadFrame
    jsr Wave_DrawBackground

    lda #8
    sta z:waves_AnimWait
    lda #0
    sta z:waves_AnimOdd

    jsr ClearSprites

    jsr Clear_GameRam
    jsr Clear_ExtendedRam

    ; Tile
    lda #SPRITE_ID_BALL
    sta Sprites+5

    lda #16
    sta Sprites+(4*6)
    sta Sprites+(4*6)+3

    lda #1
    sta Sprites+(4*6)+2

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

    ; Boost count sprite
    lda #16
    sta Sprites+(4*5)+0
    lda #24
    sta Sprites+(4*5)+3

    lda #$0D
    sta Sprites+(4*5)+1

    lda #0
    sta Sprites+(4*5)+2

    jsr WriteSprites
    jsr game_DrawWalls

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

    lda #WALL_TOP
    sta game_WallTop
    lda #WALL_BOTTOM
    sta game_WallBot
    lda #WALL_LEFT
    sta game_WallLeft
    lda #WALL_RIGHT
    sta game_WallRight

    jsr UpdatePaddleSprite

    lda CurrentBoard
    jsr LoadMap
    jsr DrawCurrentMap

    .Update_PpuControl PPU_CTRL_NMI | PPU_CTRL_VERTICAL

    ; Draw two columns of wall on the second nametable
    ; to scroll onto with a the screen shake
    lda #$24
    sta $2006
    lda #$00
    sta $2006

    ldx #30
    lda #$01
:
    sta $2007
    dex
    bne :-

    lda #$24
    sta $2006
    lda #$1F
    sta $2006

    ldx #30
    lda #$01
:
    sta $2007
    dex
    bne :-

.ifdef DEBUG
    jmp @afterRowCol ; skip but keep code, lol

    ; Add row numbers
    lda #$20
    sta $2006
    lda #$82
    sta $2006
    ldx #12
    ldy #$10
:
    sty $2007
    iny
    dex
    bne :-
.endif

    .Update_PpuControl PPU_CTRL_NMI

.ifdef DEBUG
    lda #1
    sta TmpX
    ; add column numbers
    lda #$20
    sta $2006
    lda #$44
    sta $2006
    ldx #16
    ldy #$10
:
    sty $2007
    iny
    dex
    bne :-

    ldx #8
    ldy #$10
:
    sty $2007
    iny
    dex
    bne :-

@afterRowCol:
.endif

    lda Gravity_MainMap
    sta game_currentGravity

    lda #%10001000
    sta PpuControl

    lda #$00
    sta $2005
    sta $2005

Frame_Game:
    .NMI_Set NMI_Game
    jsr ReadControllers

    ; TODO: put this in a routine
    lda LivesCount
    clc
    adc #$0A    ; offset to sprite
    sta Sprites+(4*6)+1

    ; TODO: Make this a proper sprite / UI element
    ; wtf is this doing? lmao
    bit powerup_ActiveItems
    bvc :+
    lda #$1F
    sta Sprites+(4*6)+1
:

    lda #BUTTON_SELECT
    jsr ButtonPressedP1
    beq :+
    jsr ResetBall
:

    lda BallDirection
    and #BALL_STATE_INIT
    bne @Init

    lda #BUTTON_A
    jsr ButtonPressedP1
    beq :+
    jsr BoostTheBall
:
@Init:

    jsr UpdateBallCoords
    jsr UpdatePaddleCoords

    jsr CheckWallCollide
    beq :+
    jmp Frame_Game
:

    jsr CheckBrickCollide
    beq :+
    jmp Frame_Game
:

    bit CurrentBoard
    bmi :+
    ; Skip these on child boards
    jsr powerup_CollideCheck
    jsr powerup_DoFrameAction
    jsr powerup_Animate
:

    jsr CheckPaddleCollide
    jsr UpdateBallSprite
    jsr UpdatePaddleSprite
    jsr UpdateBoostSprite


    ;jsr waves_PrepChrWrite
    jsr waves_CacheRow

    ;jsr game_DebugData

    lda #BUTTON_START
    jsr ButtonPressedP1
    beq :+
    lda controller1
    and #BUTTON_A
    beq @pause
    jmp EndLevel
@pause:
    nop
:

    jsr WaitForNMI
    jmp Frame_Game

; starting positions for sprites
DEBUG_DATA_Y = 20
DEBUG_DATA_X = 216
DEBUG_SPRITES = Sprites + (4 * 8) ; 8th sprite
DEBUG_HEX = $50 ; Tile row for hex values

game_DebugData:
    lda #DEBUG_DATA_Y
    sta DEBUG_SPRITES + (4 * 0)
    sta DEBUG_SPRITES + (4 * 1)

    lda #DEBUG_DATA_Y + 8
    sta DEBUG_SPRITES + (4 * 2)
    sta DEBUG_SPRITES + (4 * 3)

    lda #DEBUG_DATA_Y + 16
    sta DEBUG_SPRITES + (4 * 4)
    sta DEBUG_SPRITES + (4 * 5)
    sta DEBUG_SPRITES + (4 * 6)
    sta DEBUG_SPRITES + (4 * 7)

    lda #DEBUG_DATA_Y + 24
    sta DEBUG_SPRITES + (4 * 8)
    sta DEBUG_SPRITES + (4 * 9)
    sta DEBUG_SPRITES + (4 * 10)
    sta DEBUG_SPRITES + (4 * 11)

    lda #DEBUG_DATA_X
    sta DEBUG_SPRITES + 3 + (4 * 0)
    sta DEBUG_SPRITES + 3 + (4 * 2)
    sta DEBUG_SPRITES + 3 + (4 * 4)
    sta DEBUG_SPRITES + 3 + (4 * 8)

    lda #DEBUG_DATA_X + 8
    sta DEBUG_SPRITES + 3 + (4 * 1)
    sta DEBUG_SPRITES + 3 + (4 * 3)
    sta DEBUG_SPRITES + 3 + (4 * 5)
    sta DEBUG_SPRITES + 3 + (4 * 9)

    lda #DEBUG_DATA_X + 16
    sta DEBUG_SPRITES + 3 + (4 * 6)
    sta DEBUG_SPRITES + 3 + (4 * 10)

    lda #DEBUG_DATA_X + 24
    sta DEBUG_SPRITES + 3 + (4 * 7)
    sta DEBUG_SPRITES + 3 + (4 * 11)

    ; Attributes
    lda #0
    sta DEBUG_SPRITES + 2 + (4 * 0)
    sta DEBUG_SPRITES + 2 + (4 * 1)
    sta DEBUG_SPRITES + 2 + (4 * 2)
    sta DEBUG_SPRITES + 2 + (4 * 3)

    sta DEBUG_SPRITES + 2 + (4 * 4)
    sta DEBUG_SPRITES + 2 + (4 * 5)
    sta DEBUG_SPRITES + 2 + (4 * 6)
    sta DEBUG_SPRITES + 2 + (4 * 7)

    sta DEBUG_SPRITES + 2 + (4 * 8)
    sta DEBUG_SPRITES + 2 + (4 * 9)
    sta DEBUG_SPRITES + 2 + (4 * 10)
    sta DEBUG_SPRITES + 2 + (4 * 11)

    ; BallX+1
    lda BallX+1
    jsr BinToHex
    lda TmpY
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 0)
    lda TmpX
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 1)

    ; BallY+1
    lda BallY+1
    jsr BinToHex
    lda TmpY
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 2)
    lda TmpX
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 3)

    ; BallSeedX+1
    lda BallSpeedX+1
    jsr BinToHex
    lda TmpY
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 4)
    lda TmpX
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 5)

    ; BallSeedX+0
    lda BallSpeedX+0
    jsr BinToHex
    lda TmpY
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 6)
    lda TmpX
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 7)

    ; BallSeedY+1
    lda BallSpeedY+1
    jsr BinToHex
    lda TmpY
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 8)
    lda TmpX
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 9)

    ; BallSeedY+0
    lda BallSpeedY+0
    jsr BinToHex
    lda TmpY
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 10)
    lda TmpX
    ora #DEBUG_HEX
    sta DEBUG_SPRITES + 1 + (4 * 11)
    rts

NMI_Game:
    pha
    txa
    pha
    tya
    pha

    jsr WriteSprites
    jsr WritePalettes

    dec z:waves_AnimWait
    bne @noAnim
    lda #8
    sta z:waves_AnimWait

    lda z:waves_AnimOdd
    beq :+
    lda #0
    sta z:waves_AnimOdd
    lda #%10001000
    sta PpuControl
    jmp @animDone
:
    lda #1
    sta z:waves_AnimOdd
    lda #%10011000
    sta PpuControl

@animDone:
    inc z:waves_currentFrame
    lda z:waves_currentFrame
    cmp #15
    bcc :+
    lda #0
    sta z:waves_currentFrame
:
@noAnim:

    ; Destroy any bricks that need destroying
    lda BrickDestroyA+1  ;check high byte for value
    beq :+
    bit $2002
    sta $2006
    lda BrickDestroyA
    sta $2006

    lda game_PpuRow
    and #$07
    tax

    ; first tile
    lda game_PpuCol
    and #$07
    clc
    adc Index_BgAnimRows, x
    sta $2007

    bit BrickDestroyHalf
    bmi :+

    ; second tile
    lda game_PpuCol
    adc #1
    and #$07
    clc
    adc Index_BgAnimRows, x
    sta $2007
:

    lda BrickDestroyB+1  ;check high byte for value
    beq :+
    bit $2002
    sta $2006
    lda BrickDestroyB
    sta $2006

    lda game_PpuRow
    and #$07
    tax

    ; first tile
    lda game_PpuCol
    and #$07
    clc
    adc Index_BgAnimRows, x
    sta $2007

    bit BrickDestroyHalf
    bvs :+

    ; second tile
    lda game_PpuCol
    adc #1
    and #$07
    clc
    adc Index_BgAnimRows, x
    sta $2007

:
    lda #0
    sta BrickDestroyA
    sta BrickDestroyA+1
    sta BrickDestroyB
    sta BrickDestroyB+1
    sta BrickDestroyHalf

    lda z:waves_AnimOdd
    ;jsr waves_WriteRow
    jsr waves_WriteCachedRow

    bit $2002
    lda game_ScrollX
    sta $2005
    lda game_ScrollY
    sta $2005

    .Update_PpuMask PPU_MASK_ON | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND

    lda PpuControl
    ora game_Nametable
    sta $2000

    dec Sleeping

    pla
    tay
    pla
    tax
    pla
    rti

game_DrawWalls:
    bit CurrentBoard
    bmi @childBoard

    ; Right wall
    lda #$20
    sta AddressPointer0+1
    lda #$1F
    sta AddressPointer0+0

    ; bottom wall
    lda #$23
    sta AddressPointer1+1
    lda #$80
    sta AddressPointer1+0

    lda #2
    sta TmpX    ; top row count
    lda #1
    sta TmpY    ; column count for left/right

    jmp @loops

@childBoard:
    ; Right wall
    lda #$20
    sta AddressPointer0+1
    lda #$1A
    sta AddressPointer0+0

    ; bottom wall
    lda #$23
    sta AddressPointer1+1
    lda #$00
    sta AddressPointer1+0

    lda #4
    sta TmpX    ; top row count
    lda #6
    sta TmpY    ; column count for left/right

@loops:
    ; Draw top two rows
    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda #$01
    ldx TmpX
:
    .repeat 32
    sta $2007
    .endrepeat
    dex
    bne :-

    ; draw bottom two rows
    lda AddressPointer1+1
    sta $2006
    lda AddressPointer1+0
    sta $2006

    lda #$0F
    ldx TmpX
:
    .repeat 32
    sta $2007
    .endrepeat
    dex
    bne :-

    ; Draw Left (left after top to use address)
    lda #%10011100
    sta $2000

    ldy #$00
    sty TmpZ
    lda #$01
    ldx TmpY
:
    ldy #$20
    sty $2006
    ldy TmpZ
    sty $2006
    inc TmpZ

    .repeat 30
    sta $2007
    .endrepeat
    dex
    bne :-

    ; Draw Right
    lda #$01
    ldx TmpY
:
    ldy #$20
    sty $2006
    ldy AddressPointer0
    sty $2006
    inc AddressPointer0
    .repeat 30
    sta $2007
    .endrepeat
    dex
    bne :-
    rts

BoostTheBall:
    lda game_currentGravity
    bne :+
    rts
:
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
    sbc BallSpeedY+0
    sta BallSpeedY+0

    lda #0
    sbc BallSpeedY+1
    sta BallSpeedY+1

    lda BallDirection
    and #$40
    sta BallDirection
    rts

UpdateBoostSprite:
    lda game_currentGravity
    bne :+
    lda #$FF
    sta Sprites+(4*5)
    sta Sprites+(4*5)+3
    rts
:
    lda #16
    sta Sprites+(4*5)
    lda #24
    sta Sprites+(4*5)+3

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
    lda #Initial_Ball_Direction
    ora #BALL_STATE_INIT
    sta BallDirection

    lda PaddleX
    sta BallX
    lda PaddleY
    sta BallY

    lda PaddleX+1
    sta BallX+1
    lda PaddleY+1
    sta BallY+1

    ;lda #Initial_Ball_Speed_FRACT
    lda #0
    sta BallSpeedY
    sta BallSpeedX

    ;lda #Initial_Ball_Speed_WHOLE
    sta BallSpeedY+1
    sta BallSpeedX+1

    ; Reset gravity powerup
    lda Gravity_MainMap
    bne :+
    ; Turn off the gravity if you die
    lda #0
    sta game_currentGravity
    sta pu_Gravity+0
    sta pu_Gravity+1
:
    rts

; Read the button inputs and update the paddle coords accordingly
UpdatePaddleCoords:
    lda #Initial_Paddle_Speed_FRACT
    sta PaddleSpeed
    lda #Initial_Paddle_Speed_WHOLE
    sta PaddleSpeed+1


    lda BallDirection
    and #BALL_STATE_INIT
    beq @notInit

    ; When in the init state launch ball
    ; when A is pressed.
    lda #BUTTON_A
    jsr ButtonPressedP1
    beq :+
    lda BallDirection
    eor #BALL_STATE_INIT
    sta BallDirection
    jsr UpdateBallAngle
:

    lda #BUTTON_B
    jsr ButtonPressedP1
    beq :+

    lda BallDirection
    eor #BALL_STATE_INIT_LEFT
    sta BallDirection
:

@notInit:
    ; Go slower with B pressed
    lda #BUTTON_B
    and controller1
    beq :+
    lda #Paddle_Speed_Slow_FRACT
    sta PaddleSpeed
    lda #Paddle_Speed_Slow_WHOLE
    sta PaddleSpeed+1
:
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

    lda BallDirection
    and #BALL_STATE_INIT
    bne :+
    rts
:
    ; Ball is in the INIT state, move it
    ; with the paddle.
    lda PaddleX
    sta BallX
    lda PaddleY
    sta BallY
    lda BallDirection
    and #BALL_STATE_INIT_LEFT
    bne :+
    ; ball on right
    lda PaddleX+1
    clc
    adc #4
    sta BallX+1
    jmp :++
:
    ; ball on left
    lda PaddleX+1
    sec
    sbc #4
    sta BallX+1
:
    ; Put the ball just above the paddle
    lda PaddleY+1
    sec
    sbc #6
    sta BallY+1
    rts

ApplyGravity:
    lda game_currentGravity
    bne :+
    rts
:

    bit BallDirection
    bpl @down
    ;up

    lda BallSpeedY
    sec
    sbc game_currentGravity
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

    lda BallDirection
    and #BALL_STATE_INIT
    beq :+
    rts
:

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

CheckWallCollide:
    bit BallDirection
    bpl @goingDown
    ; Going up
    lda BallY+1
    cmp game_WallTop
    beq @bounceVertTop
    bcc @bounceVertTop
    jmp @checkHoriz

@goingDown:
    lda BallY+1
    cmp game_WallBot
    bcs @bounceVertBottom
    jmp @checkHoriz

@bounceVertTop:
    lda game_WallTop
    sec
    sbc BallY+1

    clc
    adc game_WallTop
    sta BallY+1
    jmp @bounceVert

@bounceVertBottom:
    bit CurrentBoard
    bpl @onMainBoard
    jmp game_ReturnToMain

@onMainBoard:
    jsr game_SubtractLife
    jsr ResetBall

    lda #1
    rts

@bounceVert:
    jsr BounceVert

@checkHoriz:
    bit BallDirection
    bvs @goingRight
    ; Going left
    lda BallX+1
    cmp game_WallLeft
    beq @bounceHorizLeft
    bcc @bounceHorizLeft
    lda #0
    rts ; return early

@goingRight:
    lda BallX+1
    cmp game_WallRight
    bcs @bounceHorizRight
    lda #0
    rts ; return early

@bounceHorizLeft:
    ; traveling right
    ; Get diff = (wall - ball)
    lda game_WallLeft
    sec
    sbc BallX+1
    ; diff in A

    ; Add difference to wall coord
    clc
    adc game_WallLeft
    sta BallX+1
    jmp @bounceHoriz

@bounceHorizRight:
    lda BallX+1
    sec
    sbc game_WallRight
    sta TmpX    ; wall - ball difference

    lda game_WallRight
    sbc TmpX
    sta BallX+1

@bounceHoriz:
    jsr BounceHoriz
    lda #0
    rts

GAMEOVER_FRAME_RATE = 12

game_GameOver:
    lda #0
    sta game_ShakeCooldown

@dedLoop:
    lda game_ShakeCooldown
    beq :+
    dec game_ShakeCooldown
    jsr WaitForNMI
    jmp @dedLoop
:

    lda #GAMEOVER_FRAME_RATE
    sta game_ShakeCooldown

    ldy #0
    ldx #32
@palLoop:
    lda PaletteBuffer, x
    cmp #$0F
    beq @next

    iny

    sec
    sbc #$10
    bpl :+
    lda #$0F
:
    sta PaletteBuffer, x

@next:
    dex
    bpl @palLoop

    tya
    beq @done

    jsr WaitForNMI
    jmp @dedLoop

@done:

    jsr WaitForNMI
    lda #InitIDs::GameOver
    jmp JumpToInit

game_SubtractLife:
    ldx #SHAKE_FRAMES
    ldy #0
    sty game_ShakeCooldown
    sty game_FlameFrame    ; flame frame
    sty game_FlameCooldown
@loop:
    jsr game_AnimateFlame

    lda game_ShakeCooldown
    beq :+
    dec game_ShakeCooldown
    jsr WaitForNMI
    jmp @loop

:
    jsr game_AnimateShake
    jsr WaitForNMI
    iny
    dex
    bne @loop

    lda #$FF
    ldx #96
:
    sta Sprites, x
    inx
    bne :-

    dec LivesCount
    beq game_GameOver

    rts

game_AnimateShake:
    lda #SHAKE_FRAME_RATE
    sta game_ShakeCooldown

    lda #0
    sta game_Nametable    ; current nametable

    bit $2002
    lda data_ScreenShake_X, y
    bpl :+
    inc game_Nametable
:
    sta game_ScrollX

    lda data_ScreenShake_Y, y
    bpl :+
    inc game_Nametable
    inc game_Nametable
:
    sta game_ScrollY
    rts

FLAME_SPRITES = Sprites+96

game_AnimateFlame:
    lda game_FlameFrame
    cmp #4
    bne :+
    rts
:
    lda game_FlameCooldown
    bpl :+
    lda #4
    sta game_FlameCooldown
    ldy game_FlameFrame
    inc game_FlameFrame

    lda DeathAnim_Tiles, y
    sta FLAME_SPRITES + 0 + 1
    sta FLAME_SPRITES + 4 + 1
    sta FLAME_SPRITES + 8 + 1
    sta FLAME_SPRITES + 16 + 1

    lda BallX+1
    sec
    sbc #Death_Offset
    sta FLAME_SPRITES + 0 + 3
    sta FLAME_SPRITES + 4 + 3
    sta FLAME_SPRITES + 8 + 3
    sta FLAME_SPRITES + 16 + 3

    lda #Death_Height
    sta FLAME_SPRITES + 0 + 0
    lda #Death_Height + 8
    sta FLAME_SPRITES + 4 + 0
    lda #Death_Height + 16
    sta FLAME_SPRITES + 8 + 0
    lda #Death_Height + 24
    sta FLAME_SPRITES + 16 + 0

    lda #0
    sta FLAME_SPRITES + 0 + 2
    sta FLAME_SPRITES + 4 + 2
    sta FLAME_SPRITES + 8 + 2
    sta FLAME_SPRITES + 16 + 2

    lda #$FF
    sta Sprites+4
:
    dec game_FlameCooldown
    rts


; Load a powerup into memory
; Powerup ID in A
powerup_Load:
    ldx PowerupCount
    inc PowerupCount
    ldy data_Mult3, x   ; Offset in PowerupList

    ; Store powerup ID (not offset)
    sta PowerupList, y

    ; X coord
    iny
    lda BallX+1
    sta PowerupList, y

    ; Y coord
    iny
    lda BallY+1
    sta PowerupList, y

    rts

; Move the powerups and write them to sprite RAM.
; Also, remove powerups that are no longer
; on screen.
powerup_Animate:

    ; loop through all powerups using two indexes: Read and Write
    ; increment read index on all elements, but only increment write
    ; on elements that still exist

    ; clear powerups from sprite RAM
    ldx #28
    lda #$FF
:
    sta Sprites, X
    inx
    sta Sprites, X
    inx
    sta Sprites, X
    inx
    sta Sprites, X
    inx
    cpx #96
    bne :-

    lda PowerupCount
    bne @hasPowerups
    rts

@hasPowerups:

    sta TmpW
    ; Clean powerup list
    ldx #0  ; read
    ldy #0  ; write
    sty PowerupCount
@cleanLoop:
    lda PowerupList+2, x    ; inspect Y
    cmp #$EF
    bcs @skip

    ; move ID
    lda PowerupList, x
    sta PowerupList, y

    ; move X
    lda PowerupList+1, x
    sta PowerupList+1, y

    ; move Y
    lda PowerupList+2, x
    sta PowerupList+2, y

    ; increment to next write slot
    iny
    iny
    iny

    inc PowerupCount
@skip:
    ; increment to next read slot
    inx
    inx
    inx
    cpx #24
    beq @cleanDone

    dec TmpW
    bne @cleanLoop

@cleanDone:
    lda #0

; Zero remaining elements
@clearLoop:
    cpy #24
    beq @clearDone
    sta PowerupList, y
    iny
    jmp @clearLoop

@clearDone:
    ; Animate active powerups
    lda PowerupCount
    bne :+
    rts ; no powerups
:
    sta TmpW
    ldx #0
    stx TmpZ    ; Loaded count
@loop:
    lda PowerupList, x
    sta IdxA

    inx
    lda PowerupList, x
    sta TmpX

    inx
    lda PowerupList, x
    sta TmpY

    ; Move it down the screen
    clc
    adc #1
    sta PowerupList, x
    inx

    ; Get offset into Powerup_* tables
    lda IdxA
    asl a
    tay

    lda Powerup_TileAttr, y
    sta IdxA    ; Tile ID

    lda Powerup_TileAttr+1, y
    sta IdxB    ; Attribute

    ; Get offset in Sprite RAM
    lda TmpZ
    clc
    adc #7
    asl a
    asl a
    tay

    lda TmpY
    sta Sprites, y

    iny
    lda IdxA
    sta Sprites, y

    iny
    lda IdxB
    sta Sprites, y

    iny
    lda TmpX
    sta Sprites, y

    inc TmpZ

    dec TmpW
    bne @loop

@end:
    rts

; Check for collisions with the paddle and call
; the correct _Action routine if needed
powerup_CollideCheck:
    ; bounding box: X+1,Y+1 and X+7,Y+7
    ; check vertical position first
    lda PowerupCount
    bne :+
    rts ; return early if there's no powerups
:

    sta TmpW    ; powerup count
    ldx #0
@loop:
    ; check bottom of powerup is above top
    ; of paddle
    lda PowerupList+2, x
    clc
    adc #7
    sta TmpY    ; collision plane on powerup

    lda PaddleY+1
    sec
    sbc #PADDLE_VERT_OFFSET
    cmp TmpY
    bcs @next   ; too far up

    ; make sure top of powerup isn't below bottom
    ; of the paddle

    lda PowerupList+2, x
    clc
    adc #1
    sta TmpY

    lda PaddleY+1
    adc #PADDLE_VERT_OFFSET
    cmp TmpY
    bcc @next   ; too far down

    ; Left side
    lda PowerupList+1, x
    clc
    adc #1
    sta TmpX

    lda PaddleX+1
    sec
    sbc #PADDLE_CENTER_WIDTH+8
    cmp TmpX
    bcs @next   ; too far left

    ; Right side
    lda PowerupList+1, x
    clc
    adc #7
    sta TmpX

    lda PaddleX+1
    adc #PADDLE_CENTER_WIDTH+8
    cmp TmpX
    bcc @next   ; too far right

    ; collided
    lda #$F0
    sta PowerupList+2, x
    txa
    pha

    lda PowerupList, x  ; load ID
    jsr powerup_DoAction

    pla
    tax

    inx
    inx
    inx
@next:
    dec TmpW
    bne @loop
    rts

powerup_DoAction:
    asl a
    tax

    lda Powerup_Actions+0, x
    sta AddressPointer0+0
    lda Powerup_Actions+1, x
    sta AddressPointer0+1
    jmp (AddressPointer0)

; Screen shake "frames"
data_ScreenShake_X:
    .byte .N 1, 1, 0, 0
    .byte .N 1, 1, 0, 0
    .byte .N 1, 1, 0, 0

data_ScreenShake_Y:
    .byte .N 1, 0, 1, 0
    .byte .N 1, 0, 1, 0
    .byte .N 1, 0, 1, 0

SHAKE_FRAMES = * - data_ScreenShake_Y
SHAKE_FRAME_RATE = 1   ; framerate of shake

pu_RefillLife_Action:
    lda #3
    sta LivesCount
    rts

pu_LoseLife_Action:
    jsr game_SubtractLife
    rts

pu_NoClip_Action:
    lda #PU_NOCLIP
    ora powerup_ActiveItems
    sta powerup_ActiveItems

    lda #0
    sta powerup_NoClip_Timer+0
    lda #1
    sta powerup_NoClip_Timer+1

    ;lda #$FF
    rts

pu_NoClip_FrameAction:
    lda powerup_NoClip_Timer+1
    bne @hasValue
    lda powerup_NoClip_Timer+0
    bne @hasValue

    ; reset powerup
    lda #0
    lda powerup_ActiveItems
    eor #PU_NOCLIP
    sta powerup_ActiveItems
    rts

@hasValue:
    lda powerup_NoClip_Timer+0
    sec
    sbc #1
    sta powerup_NoClip_Timer+0

    lda powerup_NoClip_Timer+1
    sbc #0
    sta powerup_NoClip_Timer+1
    rts

pu_Gravity_Action:
    lda #<PU_GRAVITY_DURATION
    sta pu_Gravity+0
    lda #>PU_GRAVITY_DURATION
    sta pu_Gravity+1

    lda powerup_ActiveItems
    ora #PU_GRAVITY
    sta powerup_ActiveItems

    lda #GRAVITY_VALUE
    sta game_currentGravity
    rts

pu_Gravity_FrameAction:
    lda pu_Gravity+0
    bne @on
    lda pu_Gravity+1
    bne @on

    bit powerup_ActiveItems
    bmi @off  ; powerup active, needs to be turned off
    rts
@off:
    ; turn off the bit.  gravity will turn off on next
    ; paddle bounce.
    lda powerup_ActiveItems
    eor #PU_GRAVITY
    sta powerup_ActiveItems
    rts

@on:
    lda pu_Gravity+0
    sec
    sbc #1
    sta pu_Gravity+0

    lda pu_Gravity+1
    sbc #0
    sta pu_Gravity+1
    rts

powerup_DoFrameAction:
    lda #$FF
    bit powerup_ActiveItems
    bne :+  ; Zero == no active items
    rts
:
    bvc :+
    jsr pu_NoClip_FrameAction
:

    bit powerup_ActiveItems
    bpl :+
    jsr pu_Gravity_FrameAction
:
    rts

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
    lda Gravity_MainMap
    bne :+
    ; Turn off gravity if it was turned on by an item
    ; and the timer ran out.
    bit powerup_ActiveItems
    bmi :+
    lda #0
    sta game_currentGravity
:

    lda game_currentGravity
    beq :+
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

; Check for a collision between the ball and the
; left or right side of the paddle.  The ball will
; bounce horizontally, but not vertically.
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
    ; TODO: remove these constants
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
    ; TODO: remove these constants
    sbc #PADDLE_CENTER_WIDTH + EDGE_COLLIDE_OFFSET + 1
    cmp BallX+1
    bcc :+
    rts ; ball is to the right of paddle
:
    jmp BounceHoriz

; Main entry point for ball to brick collisions.
; First, the vertical collisions are checked (brick top
; or brick bottom, depending on ball travel direction),
; the the horizontal collisions are checked (brick left
; or right).
;
; The collision detection uses two points per side of the
; ball.  The two points are checked for colliding with a
; brick.  If both points collide with the same brick, do
; the brick action on that brick.  Otherwise, if the ball
; collides with two different bricks, check a third point
; of collision between the original two points and collide
; against that brick.
;
; Even though "check" is in the name, the collisions are
; acted upon in this routine.  That includes bouncing the
; ball, removing bricks, and spawning child boards.
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

    ; Something collided, check for adjacent brick.
    ; This is to avoid colliding with a edge that is
    ; touching another brick.
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

.ifdef DEBUG
    ; sanity check
    cpx #16
    bcc :+
    brk ; X is too large
:

    cpy #24
    bcc :+
    brk ; Y is too large
:
.endif

    stx BrickRow
    sty BrickCol
    jsr GetAddressesForBrick

    ldy #0
    lda (BrickAddress), y
    ; There is an adjacent brick, do
    ; not collide with that brick.
    bne @noVertCollide

@vertDoCollide:
    ; Something collided, store it
    lda CollisionRow_Ret
    sta BrickRowIndex_Vert
    and #$7F
    tax

    lda CollisionCol_Ret
    sta BrickColIndex_Vert
    tay

    stx BrickRow
    sty BrickCol
    jsr GetAddressesForBrick

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

    stx BrickRow
    sty BrickCol
    jsr GetAddressesForBrick

    ldy #0
    lda (BrickAddress), y
    bne @noHorizCollide ; there is a brick, do not collide

@horizDoCollide:
    ; Something collided, store it
    lda CollisionRow_Ret
    sta BrickRowIndex_Horiz
    and #$7F
    tax

    lda CollisionCol_Ret
    sta BrickColIndex_Horiz
    tay

    stx BrickRow
    sty BrickCol
    jsr GetAddressesForBrick

    jmp @doCollisions

@noHorizCollide:
    lda #0
    sta BrickRowIndex_Horiz
    sta BrickColIndex_Horiz

@doCollisions:

    bit BrickRowIndex_Vert
    bpl :+
    jsr DoVerticalBrickCollide
    bne :++ ; DoBrickAction returns 1 if
            ; everything else should be skipped.
:           ; "everything" is to be determined.

    bit BrickRowIndex_Horiz
    bpl :+
    jsr DoHorizontalBrickCollide
:
    rts

; Get the address for the brick on the child board
; at the given row and column coordinates.
;
; Both the address in RAM and the address in the PPU
; are calculated here.
;
; Input: BrickRow, Brickcol
; Output: BrickAddress, BrickPpuAddress
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
    adc BrickCol
    adc BrickAddress
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
    dec BrickCol
    dec BrickAddress
    jmp :+
@decBoth:
    dec BrickAddress
    dec BrickAddress+1
:

    lda BrickRow
    asl a
    tax

    ; high byte
    lda Index_PpuChildBrickRows+1, x
    sta BrickPpuAddress+1

    ; low byte
    lda Index_PpuChildBrickRows, x

    clc
    adc BrickCol
    sta BrickPpuAddress

    bcc :+
    inc BrickPpuAddress+1
:
    lda game_BoardOffsetY
    lsr a   ; offset is in pixels
    lsr a   ; divide it by 8
    lsr a
    clc
    adc BrickRow
    sta game_PpuRow

    lda game_BoardOffsetX
    lsr a   ; offset is in pixels
    lsr a   ; divide it by 8
    lsr a
    clc
    adc BrickCol
    sta game_PpuCol

    rts

; Get the address for the brick on the main board
; at the given row and column coordinates.
;
; Both the address in RAM and the address in the PPU
; are calculated here.
;
; A brick address should always be returned.  Empty tiles
; SHOULD NOT be returned.
;
; Input: BrickRow, BrickCol
; Output: BrickAddress, BrickPpuAddress
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
    ldy BrickCol
    lda (BrickAddress), y   ; BrickAddress is the start of the row
    bpl :++
    lda BrickCol
    bne :+
:
    ; On second byte, subtract one to get first byte
    dec BrickCol
:

    lda game_BoardOffsetY
    lsr a   ; offset is in pixels
    lsr a   ; divide it by 8
    lsr a
    clc
    adc BrickRow
    sta game_PpuRow

    lda game_BoardOffsetX
    lsr a   ; offset is in pixels
    lsr a   ; divide it by 8
    lsr a
    clc
    adc BrickCol
    sta game_PpuCol

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

    ; High byte
    lda Index_PpuBrickRows+1, x
    sta BrickPpuAddress+1

    ; low byte
    lda Index_PpuBrickRows, x
    clc
    adc BrickCol
    sta BrickPpuAddress

    lda BrickPpuAddress+1
    adc #0
    sta BrickPpuAddress+1
    rts

; Perform the vertical collision on a brick.
;
; First determine the vertical direction of travel,
; then determine how far the ball is embedded into
; the brick.
;
; The ball will be moved in the oposite direction of
; movement so it is no longer embedded in the brick.
; The distance moved is determined by the difference
; between the wall of the brick and the Y coordinate
; of the ball.
;
; Lastly, reverse the ball's direction of travel.
;
; Input: BrickRowIndex_Vert, BrickColIndex_Vert, BallY
DoVerticalBrickCollide:
    ; Determine up or down travel
    ; find the brick coordinate bounds
    ; find the distance into the brick the ball is
    ; add that distance to the opposite direction of the ball
    lda BrickRowIndex_Vert
    and #$7F

    sta BrickRow
    lda BrickColIndex_Vert
    sta BrickCol

    bit powerup_ActiveItems
    bvc @noNoClip
    jmp game_RemoveBrick

@noNoClip:

    lda BrickRowIndex_Vert
    and #$7F
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
    jmp BrickBounceVert

@goingUp:
    ; distance into brick = Wall - BallY
    lda (Address_RowCoordBot), y
    sec
    sbc BallY+1

    clc
    adc (Address_RowCoordBot), y
    sta BallY+1

    jmp BrickBounceVert

; Perform the horizontal collision on a brick.
;
; First determine the horizontal direction of travel,
; then determine how far the ball is embedded into
; the brick.
;
; The ball will be moved in the oposite direction of
; movement so it is no longer embedded in the brick.
; The distance moved is determined by the difference
; between the wall of the brick and the Y coordinate
; of the ball.
;
; Lastly, reverse the ball's direction of travel.
;
; Input: BrickRowIndex_Horiz, BrickColIndex_Horiz, BallX
DoHorizontalBrickCollide:
    lda BrickRowIndex_Horiz
    and #$7F
    sta BrickRow
    lda BrickColIndex_Horiz
    sta BrickCol

    bit powerup_ActiveItems
    bvc @noNoClip
    jmp game_RemoveBrick
@noNoClip:

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
    jmp BrickBounceHoriz

@goingLeft:
    ; distance into wall = RightWall - BallX - EdgeOffset
    lda (Address_RowCoordRight), y
    sbc BallX+1 ; subtract collision point

    clc
    adc (Address_RowCoordRight), y
    sta BallX+1

    jmp BrickBounceHoriz

BrickBounceVert:
    ; Bit 7 is vertical
    lda BallDirection
    eor #$80
    sta BallDirection
    jmp DoBrickAction

BrickBounceHoriz:
    ; Bit 6 is horizontal
    lda BallDirection
    eor #$40
    sta BallDirection
    jmp DoBrickAction

; Swap the ball's vertical movement direction.
BounceVert:
    ; Bit 7 is vertical
    lda BallDirection
    eor #$80
    sta BallDirection
    rts

; Swap the ball's horizontal movement direction.
BounceHoriz:
    ; Bit 6 is horizontal
    lda BallDirection
    eor #$40
    sta BallDirection
    rts

; Check if the given point, determined by TmpX and
; TmpY collide with a brick.
;
; First, verify the point is within the bounds of the
; playfield.  If the point is outside the bounds there
; cannot be a brick collision, therefore return early.
;
; If the point is within the bounds of the playfield,
; subtract the board's offset and divide the X and Y
; coordinates by eight to get the row and column
; coordinates of a tile location.
;
; Load the tile loaction and return.  No further
; processing on the brick is done aside from loading
; it in A.
;
; Input: TmpY, TmpX
; Output: A, X, Y (a = brick, X/Y = row column of brick)
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

game_ReturnToMain:
    .NMI_Disable
    jsr WaitForNMI

    .Disable_Drawing

    lda #0
    jsr FillNametable0
    jsr ClearAttrTable0

    jsr Wave_DrawBackground

    lda Gravity_MainMap
    sta game_currentGravity

    lda #BOARD_HEIGHT
    sta game_BoardHeight
    lda #BOARD_WIDTH
    sta game_BoardWidth

    lda #BOARD_OFFSET_Y
    sta game_BoardOffsetY
    lda #BOARD_OFFSET_X
    sta game_BoardOffsetX

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

    lda #Initial_Paddle_X
    sta PaddleX+1
    lda #Initial_Paddle_Y
    sta PaddleY+1

    lda #0
    sta PaddleX
    sta PaddleY

    lda #WALL_TOP
    sta game_WallTop
    lda #WALL_BOTTOM
    sta game_WallBot
    lda #WALL_LEFT
    sta game_WallLeft
    lda #WALL_RIGHT
    sta game_WallRight

    lda #PADDLE_WALL_LEFT
    sta game_PaddleWallLeft
    lda #PADDLE_WALL_RIGHT
    sta game_PaddleWallRight

    ; restore the state
    lda backup_BallDirection
    sta BallDirection
    lda backup_BallX+0
    sta BallX+0
    lda backup_BallX+1
    sta BallX+1

    lda backup_BallY+0
    sta BallY+0
    lda backup_BallY+1
    sta BallY+1

    lda backup_BallSpeedX+0
    sta BallSpeedX+0
    lda backup_BallSpeedX+1
    sta BallSpeedX+1

    lda backup_BallSpeedY+0
    sta BallSpeedY+0
    lda backup_BallSpeedY+1
    sta BallSpeedY+1

    lda backup_PaddleX+0
    sta PaddleX+0
    lda backup_PaddleX+1
    sta PaddleX+1

    lda backup_PaddleY+0
    sta PaddleY+0
    lda backup_PaddleY+1
    sta PaddleY+1

    lda game_currentGravity
    beq :+
    ; restore boost sprite
:

    lda ParentBoard
    sta CurrentBoard

    lda ChildBrickCount
    bne :+
    ; Remove brick from ram before drawing board, only if
    ; the child board was cleared
    ldy #0
    lda #0
    sta (EnteredRam), y
    iny
    sta (EnteredRam), y

    jsr game_decBrickCount
:

    ;jsr ResetBall
    jsr DrawCurrentMap

    jsr game_DrawWalls

    rts

; Read the current main map in RAM and draw it to the screen
DrawCurrentMap:
    lda #$90
    sta $2000

    lda #0
    sta TmpX
    sta TmpW
    sta MainBrickCount+0
    sta MainBrickCount+1

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

    lda TmpW
    clc
    adc MainBrickCount+0
    sta MainBrickCount+0

    bcc :+
    inc MainBrickCount+1
:
    lda #0
    sta TmpW

    ; Are we done?
    inc TmpX
    lda TmpX
    cmp game_BoardHeight
    bne @loop

    rts

; Expects the PPU address to already be set.
game_DrawRow:
    lda game_BoardOffsetY
    lsr a   ; offset is in pixels
    lsr a   ; divide it by 8
    lsr a
    clc
    adc TmpX    ; TmpX is row
    sta game_PpuRow

    lda game_BoardOffsetX
    lsr a   ; offset is in pixels
    lsr a   ; divide it by 8
    lsr a
    sta game_PpuCol

    ldy #0
@loop:
    lda (AddressPointer0), y
    beq @noTile

    ; Id -> lookup index
    and #$0F
    sec
    sbc #1  ; "health" is id 1, but index 0
    cmp #3
    beq @half
    asl a
    tax

    inc game_PpuCol
    inc game_PpuCol

    lda Index_TileDefs, x
    sta $2007
    lda Index_TileDefs+1, x
    sta $2007

    ; Brick count
    inc TmpW

    iny
    iny
    cpy game_BoardWidth
    bne @loop
    rts

@half:
    inc game_PpuCol
    lda #HalfBrickID
    sta $2007

    ; Brick count
    inc TmpW

    iny
    cpy game_BoardWidth
    bne @loop
    rts

@noTile:

    lda game_PpuRow
    and #$07
    tax

    lda game_PpuCol
    and #$07
    clc
    adc Index_BgAnimRows, x
    sta $2007

    inc game_PpuCol
    iny
    cpy game_BoardWidth
    bne @loop
    rts

; Check two point's collision and return
; the proper brick it collided with.
; Return values in CollisionRow_Ret and CollisionCol_Ret
; TODO: fix this.  There's at least one off-by-one in here (column) (is there?)
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
    ldy #0
    lda (BrickAddress), y
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

; Spawn the child board
game_ActionSpawn:
    ; Save the brick addresses for when we
    ; leave the child board.
    ; TODO: make this a pointer to a pointer.
    ;       The idea being it can be located after child
    ;       map data for nested maps.
    ; NOTE: child board id 0x10 (16) is a board with
    ;       more spawn blocks.  This breaks things.
    lda BrickAddress
    sta EnteredRam
    lda BrickAddress+1
    sta EnteredRam+1

    ; Remove all powerups on screen
    lda #0
    sta PowerupCount

    ; clear powerups from sprite RAM
    ldx #28
    lda #$FF
:
    sta Sprites, X
    inx
    sta Sprites, X
    inx
    sta Sprites, X
    inx
    sta Sprites, X
    inx
    cpx #96
    bne :-

    ldy #1
    lda (BrickAddress), y
    and #$7F
    sta ChildId    ; Child board index.  Either in RAM or ROM.

    ; Is the child board already loaded into memory?
    ldy #0
    lda (BrickAddress), y
    and #$30
    bne @drawChildMap

    ; backup the main board's state
    lda BallDirection
    sta backup_BallDirection

    lda BallX+0
    sta backup_BallX+0
    lda BallX+1
    sta backup_BallX+1

    lda BallY+0
    sta backup_BallY+0
    lda BallY+1
    sta backup_BallY+1

    lda BallSpeedX+0
    sta backup_BallSpeedX+0
    lda BallSpeedX+1
    sta backup_BallSpeedX+1

    lda BallSpeedY+0
    sta backup_BallSpeedY+0
    lda BallSpeedY+1
    sta backup_BallSpeedY+1

    lda PaddleX+0
    sta backup_PaddleX+0
    lda PaddleX+1
    sta backup_PaddleX+1

    lda PaddleY+0
    sta backup_PaddleY+0
    lda PaddleY+1
    sta backup_PaddleY+1

    ; Set child board as loaded
    lda (BrickAddress), y
    ora #$30
    sta (BrickAddress), y

    ; load map
    lda CurrentBoard
    sta ParentBoard
    lda ChildId
    jsr LoadChildMap

    ; Update ChildID in the brick
    lda #$80    ; Load the magic number for
                ; a brick's second byte.
    ora ChildId
    ldy #1
    sta (BrickAddress), y

@drawChildMap:
    lda ChildId
    ora #$80
    sta CurrentBoard

    ; Map is loaded, draw it

    .NMI_Disable
    jsr WaitForNMI

    ; Turn off BG and sprites
    .Disable_Drawing

    lda #0
    jsr FillNametable0
    jsr ClearAttrTable0

    jsr Wave_DrawBackground

    lda ChildId
    asl a
    tax

    ; Get the start address of the child map
    ; in RAM.
    lda Child_Map_Addresses, x
    sta AddressPointer0
    lda Child_Map_Addresses+1, x
    sta AddressPointer0+1

    ldy #$48
    lda (AddressPointer0), y
    sta game_currentGravity

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

    lda #Initial_Paddle_X
    sta PaddleX+1
    lda #Child_Paddle_Y
    sta PaddleY+1

    lda #CHILD_WALL_TOP
    sta game_WallTop
    lda #CHILD_WALL_BOTTOM
    sta game_WallBot
    lda #CHILD_WALL_LEFT
    sta game_WallLeft
    lda #CHILD_WALL_RIGHT
    sta game_WallRight

    lda #CHILD_PADDLE_WALL_LEFT
    sta game_PaddleWallLeft
    lda #CHILD_PADDLE_WALL_RIGHT
    sta game_PaddleWallRight

    lda #0
    sta TmpX
    sta TmpW

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

    jsr game_DrawWalls

    ; Store brick count
    lda TmpW
    sta ChildBrickCount

    lda PpuControl
    sta $2000

    jsr ResetBall

    .NMI_Set NMI_Game

    lda #1
    rts

game_ActionItemDrop:
    ; TODO: item drops
    lda BrickAddress+1
    sta AddressPointer0+1

    lda BrickAddress
    clc
    adc #1
    sta AddressPointer0
    bcc :+
    inc AddressPointer0+1
:

    ldy #0
    lda (AddressPointer0), y
    and #$7F    ; Mask off the upper bit
    jsr powerup_Load

    jmp game_RemoveBrick

game_RemoveBrick:
    jsr game_decBrickCount

    ; Remove brick from screen

    ; First check if we already have to remove a brick.
    ; If so, use the second variable
    lda BrickDestroyA
    bne :+
    lda BrickPpuAddress
    sta BrickDestroyA
    lda BrickPpuAddress+1
    sta BrickDestroyA+1
    jmp @aDone
:
    lda BrickPpuAddress
    sta BrickDestroyB
    lda BrickPpuAddress+1
    sta BrickDestroyB+1

@aDone:
    ; Remove from RAM
    lda #0
    ldy #0
    sta (BrickAddress), y
    iny
    sta (BrickAddress), y

    lda #0
    rts

game_decBrickCount:
    bit CurrentBoard
    bpl @decMain
    ; Check if this brick is the last one.
    dec ChildBrickCount
    bne @rts
    ; Board is empty, draw parent board
    jsr game_ReturnToMain
    lda #0
    rts

@decMain:
    ; Decrement counter
    lda MainBrickCount+0
    sec
    sbc #1
    sta MainBrickCount+0
    bcs :+
    dec MainBrickCount+1
:

    lda MainBrickCount+0
    bne @rts
    lda MainBrickCount+1
    bne @rts
    jmp EndLevel
@rts:
    rts

game_ActionHalf:
    ldy #0
    tya

    sta (BrickAddress), y
    lda BrickDestroyA
    bne :+

    lda BrickPpuAddress
    sta BrickDestroyA
    lda BrickPpuAddress+1
    sta BrickDestroyA+1

    jsr game_decBrickCount

    lda #$80
    sta BrickDestroyHalf
    lda #0
    rts
:
    lda BrickPpuAddress
    sta BrickDestroyB
    lda BrickPpuAddress+1
    sta BrickDestroyB+1

    jsr game_decBrickCount

    lda #$C0
    sta BrickDestroyHalf
    lda #0
    rts

Clear_GameRam:
    ldx #0
    lda #0
:
    sta GAME_RAM_START, x
    inx
    cpx #GAME_MAINRAM_SIZE
    bne :-

    ldx #0
:
    sta GAME_ZPRAM_START, x
    inx
    cpx #GAME_ZPRAM_SIZE
    bne :-

    rts

EndLevel:
    lda CurrentBoard
    cmp #15 ; Boss level
    bne :+
    jsr WaitForNMI
    lda #InitIDs::GameWon
    jmp JumpToInit
:
    sta menu_PrevLevel
    jsr WaitForNMI
    lda #InitIDs::LevelSelect
    jmp JumpToInit

NoTileID = $00
HalfBrickID = $0E
Index_TileDefs:
    .byte $02, $03  ; Health
    .byte $04, $05  ; Spawn
    .byte $06, $07  ; Item drops

BrickActions:
    .word game_ActionHealth
    .word game_ActionSpawn
    .word game_ActionItemDrop
    .word game_ActionHalf

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

Powerup_TileAttr:
    ; Refill Life
    .byte $10
    .byte $02

    ; Lose Life
    .byte $11
    .byte $02

    ; No Clip
    .byte $12
    .byte $02

    ; Gravity
    .byte $10
    .byte $02

Powerup_Actions:
    .word pu_RefillLife_Action
    .word pu_LoseLife_Action
    .word pu_NoClip_Action

    ; Not implemented
    .word pu_Gravity_Action ; Turn on gravity for X frames
    ;.word pu_Respawn_Action ; Respawn random bricks
    ;.word pu_LightsOut_Action ; "Turn off the lights" via the palette
    ;.word pu_SafetyNet_Action ; A wall under the paddle that will bounce the
                              ; ball once before disappearing

    ; "Maybies"
    ;.word pu_LargeBall_Action  ; This would require duplicate lookup tables
                                ; for collision detection stuff

DeathAnim_Tiles:
;    ; Frame 1
;    .byte $22, $32, $42
;    ; Frame 2
;    .byte $21, $31, $41
;    ; Frame 3
;    .byte $20, $30, $40

    .byte $23
    .byte $24
    .byte $25
    .byte $26

; Tile ID's of the start of each row of tiles in
; the background animation.
Index_BgAnimRows:
    .repeat 8, i
    .byte (i * 8) + $C0
    .endrepeat
