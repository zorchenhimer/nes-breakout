; asmsyntax=ca65

.segment "ZEROPAGE" : zeropage

TextPointer:    .res 2

ChrAddr:    .res 2
ChrCount:   .res 1  ; Tile count, not byte count

TextIdx:    .res 1  ; current index in the name buffer
ChrBufferIdx:   .res 1

ChrOffset:  .res 1  ; Starting offset for a character
ChrWidth:       .res 1
;ChrShiftRight: .res 1   ; Start of char
ChrShiftLeft:   .res 1  ; overflow char
ChrBufferReady: .res 1
ChrCurrentRow:  .res 1
ChrOverflow:    .res 1  ; number of overflowed columns

TextBuffer: .res 21

.segment "BUFFRAM"
ChrBuffer:  .res 18 * 8
