; asmsyntax=ca65

.pushseg
.segment "RAMGAME"
; Overworld map
CurrentMap: .res (BOARD_WIDTH * BOARD_HEIGHT)

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
HorizDestroy:   .res 2
VertDestroy:    .res 2

BoostPool:  .res 1
ChildId:    .res 1 ; next child ID to load

NextChildOffset:    .res 1

.popseg
