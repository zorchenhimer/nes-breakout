; asmsyntax=ca65

.segment "ZEROPAGE" : zeropage

TextPointer:    .res 2
TextEor: .res 1

ChrBufferIdx:   .res 1

ChrOffset:  .res 1  ; Starting offset for a character
ChrWidth:       .res 1
;ChrShiftRight: .res 1   ; Start of char
ChrShiftLeft:   .res 1  ; overflow char
ChrBufferReady: .res 1
ChrCurrentRow:  .res 1
ChrOverflow:    .res 1  ; number of overflowed columns
TextIdx:    .res 1  ; current index in the name buffer

; A single glyph being worked on
WorkingRuneA: .res 8
WorkingRuneB: .res 8

.segment "MAINRAM"

;ChrAddr:    .res 2
ChrCount:   .res 1  ; Tile count, not byte count

TextBuffer: .res 21
;txt_NoClear: .res 1

.segment "BUFFRAM"
ChrBuffer:  .res 18 * 8
