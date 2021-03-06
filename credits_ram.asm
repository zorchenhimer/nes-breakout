; asmsyntax=ca65

.pushseg
.segment "MAINRAM"

CREDIT_RAM_START = *
cr_frameOdd:    .res 1
cr_chunkCurrent: .res 1  ; current name
cr_chunkLength:  .res 1  ; length of the current chunk
cr_currentPPULine: .res 1   ; index in the PPU address lookup table

cr_currentAttrOffset:   .res 1  ; offset for the Attribute lookup table

cr_scroll:          .res 1  ; 0-240
cr_scroll_table:    .res 1  ; nametable to use (value written to $2000)
cr_tmpByte:         .res 1
cr_scrollWait:      .res 1  ; frames to wait for the next scroll
cr_nextChunkWait:   .res 1  ; scroll lines until the next chunk update
cr_UpdateReady:     .res 1  ; is there a tile or attribute update ready for the PPU?
cr_AttributeReady:  .res 1
cr_AttrSecondWrite: .res 1
cr_AttrTmp:        .res 1

cr_tileBufferOffset:    .res 1
cr_AttributeByte:       .res 1
cr_loopCounter:         .res 1
cr_t2Count:             .res 1
cr_nameLength:          .res 1

cr_tier2Color:  .res 1
cr_tier3Color:  .res 1

cr_nextGroup:   .res 1
cr_currentGroup: .res 1
cr_nextGroupPaused: .res 1
cr_singleScreen: .res 1
cr_scrollToPause: .res 1

cr_TileBuffer:  .res 64
;.align 128
cr_attribBuffer: .res 32*4

CREDIT_RAM_SIZE = * - CREDIT_RAM_START

.popseg
