; asmsyntax=ca65

.pushseg

.segment "ZEROPAGE" : zeropage

; Bit 7
;   0 - Down
;   1 - Up
; Bit 6
;   0 - Left
;   1 - Right
; Bit 0
;   0 - moving state
;   1 - init state (attached to paddle)
BALL_STATE_MOVING = $00
BALL_STATE_INIT = $01
BALL_STATE_INIT_LEFT = $02

BALL_DIR_UP = $80
BALL_DIR_DOWN = $00

BALL_DIR_RIGHT = $40
BALL_DIR_LEFT = $00

; Bit 7 - If 1, we're in a child board.
;         If 0, we're in the main board
; Bits 6-0: board ID in RAM
CurrentBoard: .res 1

GAME_ZPRAM_START = *
BallDirection: .res 1

; Coordinates with sub-pixel accuracy
; These are unsigned
; First byte is fraction, second is whole
BallX:  .res 2
BallY:  .res 2

PaddleX:  .res 2
PaddleY:  .res 2

; These are signed
; First byte is unsigned decimal, second is signed integer
BallSpeedX: .res 2
BallSpeedY: .res 2

; Only added/subtracted to/from the Paddle's X/Y while
; movement buttons are held down.
PaddleSpeed:    .res 2

BrickPpuAddress:    .res 2
BrickAddress:       .res 2
BrickRow:           .res 1
BrickCol:           .res 1

game_BoardOffsetY:  .res 1
game_BoardOffsetX:  .res 1
game_BoardWidth:    .res 1
game_BoardHeight:   .res 1

game_PaddleWallLeft:    .res 1
game_PaddleWallRight:   .res 1

game_WallTop:   .res 1
game_WallBot:   .res 1
game_WallLeft:  .res 1
game_WallRight: .res 1

; The gravity value for the currently
; loaded map (either main or child).
game_currentGravity: .res 1
ParentBoard: .res 1

Address_RowCoordTop:    .res 2
Address_RowCoordBot:    .res 2
Address_RowCoordLeft:   .res 2
Address_RowCoordRight:  .res 2

; Row/Column for background anmiation
; drawing under playfield
game_PpuRow: .res 1
game_PpuCol: .res 1

ChildBrickCount: .res 1

; Pointer to spawn brick
EnteredRam:   .res 2

game_ScrollX: .res 1
game_ScrollY: .res 1
game_Nametable: .res 1
game_ShakeCooldown: .res 1
game_FlameCooldown: .res 1
game_FlameFrame: .res 1

powerup_FrameAction_Pointer: .res 2
powerup_FrameAction_Value: .res 2

powerup_NoClip_Active: .res 1

; Length of ZP ram for the game
GAME_ZPRAM_SIZE = * - GAME_ZPRAM_START

.segment "MAINRAM"
; Overworld map
CurrentMap: .res (BOARD_WIDTH * BOARD_HEIGHT)

GAME_RAM_START = *
; Bit 7 is set when these have a valid value
BrickRowIndex_Horiz:    .res 1
BrickColIndex_Horiz:    .res 1
BrickRowIndex_Vert:    .res 1
BrickColIndex_Vert:    .res 1

CollideRow_A:  .res 1
CollideCol_A:  .res 1
CollideRow_B:  .res 1
CollideCol_B:  .res 1

CollisionRow_Ret:   .res 1
CollisionCol_Ret:   .res 1

BrickCollide1_Row:  .res 1
BrickCollide1_Col:  .res 1
BrickCollide2_Row:  .res 1
BrickCollide2_Col:  .res 1

PointA_X:   .res 1
PointA_Y:   .res 1
PointB_X:   .res 1
PointB_Y:   .res 1

; PPU Addresses to destroy bricks on the PPU
BrickDestroyA:    .res 2
BrickDestroyB:    .res 2
BrickDestroyHalf: .res 1 ; bit 7 is A, bit 6 is B

BoostPool:  .res 1
ChildId:    .res 1 ; next child ID to load

NextChildOffset:    .res 1

; Gravity setting for the currently loaded main map.
Gravity_MainMap: .res 1

PowerupCount: .res 1
PowerupList: .res (8 * 3) ; Three byte elements

GAME_MAINRAM_SIZE = * - GAME_RAM_START
;.out .sprintf("GAME_MAINRAM: %d (size: %d)", GAME_MAINRAM, .addrsize(GAME_MAINRAM))

LivesCount: .res 1
MainBrickCount: .res 2

backup_BallDirection: .res 1
backup_BallX: .res 2
backup_BallY: .res 2

backup_PaddleX:  .res 2
backup_PaddleY:  .res 2

backup_BallSpeedX: .res 2
backup_BallSpeedY: .res 2

.popseg
