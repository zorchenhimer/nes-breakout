; asmsyntax=ca65

; Load screen data to the PPU
; TODO: add offset opcode ("start at PPU address")
; TODO: add clear option to load screen? (ie, write $FF unitl the address given in offset opcode)
; TODO: figure out including attribute data in scene data

ScreenTest_Palette:
    .byte $0F, $0F, $00, $10
    .byte $0F, $00, $20, $10

StaticPalettes:
    .byte $0F, $10, $00, $2D
    .byte $0F, $2D, $10, $00
    .byte $0F, $00, $2D, $10
    .byte $0F, $0F, $00, $2D

; Quadrants of the attribute data for better readability
ST_BOTL = %0011_0000
ST_BOTR = %1100_0000
ST_TOPL = %0000_0011
ST_TOPR = %0000_1100

SCREEN_ATTR_TV = %0101_0101
SCREEN_ATTR_ST = %1111_1111

STATIC_START_OFFSET = 1
STATIC_ANIM_RATE = 3
STATIC_TRAVEL_RATE = 4
STATIC_ROW_COUNT = 4

Init_ScreenTest:
    .NMI_Disable
    .Disable_Drawing

    jsr ClearSprites
    jsr WriteSprites
    jsr ClearAttrTable0
    jsr ClearAttrTable1

    ;lda #ScreenIDs::News
    lda #ScreenIDs::Hood
    ldx #$20
    jsr LoadScreen

    lda #ScreenIDs::TvStatic
    ldx #$24
    jsr LoadScreen

    lda #ScreenIDs::TextBox
    ldx #$20
    jsr LoadScreen

    lda #6
    jsr LoadChrData

    lda #7
    jsr LoadChrData

    ldx #0
:
    lda ScreenTest_Palette, x
    sta PaletteBuffer, x
    sta PaletteBufferSprites, x
    inx
    cpx #8
    bne :-

    jsr WritePalettes

    jsr WriteTvAttr
    jsr WriteStaticAttributes

    lda #STATIC_START_OFFSET
    sta IdxB

    lda #0
    sta IdxC
    sta TmpW ; Static palette animation frame

    lda #6
    sta IdxD

    ; Static palette animation interval
    lda #STATIC_ANIM_RATE
    sta TmpX

    ; Speed static bars travel down the screen
    lda #STATIC_TRAVEL_RATE
    sta TmpY

    .Update_PpuControl PPU_CTRL_NMI
    .Update_PpuMask 0

    jsr WaitForNMI

    ; cycles per scanline: 113 1/3
Frame_ScreenTest:
    .NMI_Set NMI_ScreenTest

    dec TmpX
    lda TmpX
    bne :+

    lda #STATIC_ANIM_RATE
    sta TmpX

    inc TmpW
    lda TmpW
    cmp #4
    bcc :+
    lda #0
    sta TmpW
:

;    ; This controller code moved the start point up and down
;    jsr ReadControllers
;    lda #BUTTON_UP
;    jsr ButtonPressedP1
;    beq :+
;    dec IdxB
;:
;
;    lda #BUTTON_DOWN
;    jsr ButtonPressedP1
;    beq :+
;    inc IdxB
;:

    ; Turn static on and off on an interval of 6 frames
    dec IdxD
    bne :+
    lda #30
    sta IdxD

    lda FlipFlop
    eor #$FF
    sta FlipFlop

    ; reset the static start line
    lda #STATIC_START_OFFSET
    sta IdxB
:

    lda FlipFlop
    beq @NoStatic

    ; store the number of static blocks
    lda #STATIC_ROW_COUNT
    sta IdxA

    ; increment the static start line

    dec TmpY
    bne :+
    lda #STATIC_TRAVEL_RATE
    sta TmpY

    inc IdxB
:

    lda #PPU_CTRL_NMI | PPU_CTRL_SP_PATTERN | 1

    jsr WaitForSpriteZero
    ;sta $2005
    ;stx $2005

    ldy #PPU_CTRL_NMI | PPU_CTRL_SP_PATTERN | 0

    ; Wait an offset number of scanlines before starting static
    ldx IdxB
:
    jsr WaitScanline
    dex
    bne :-
    sta $2000

; Turn static on and off every ~4 lines
@static:

    ldx #12
; Turn on
:
    jsr WaitScanline
    dex
    bne :-
    sty $2000

    dec IdxA
    bne :+
    jmp @staticDone
:

    ldx #12
; Turn off
:
    jsr WaitScanline
    dex
    bne :-
    sta $2000
    jmp @static

@staticDone:
    sty $2000

@NoStatic:

    jsr WaitForNMI
    jmp Frame_ScreenTest

WaitScanline:
    ora IdxC
    .repeat 46
    nop
    .endrepeat
    rts

NMI_ScreenTest:
    jsr WriteSprites

    ; Write the appropriate static palette to the PPU
    lda TmpW
    asl a
    asl a
    tax

    lda #$3F
    sta $2006
    lda #$0C
    sta $2006

    ldy #4
:
    lda StaticPalettes, x
    sta $2007
    inx
    dey
    bne :-

    .Update_PpuControl PPU_CTRL_NMI | PPU_CTRL_SP_PATTERN
    .Update_PpuMask PPU_MASK_ON | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND

    lda #0
    sta $2005
    sta $2005
    dec Sleeping
    rti

; Fill the second nametable with static
FillStatic:
    lda #$20
    sta $2006
    lda #$C8
    sta $2006

    .repeat 5
    ldx #$1A
    sta 2007
    inx
    sta 2007
    inx
    sta 2007
    inx
    sta 2007
    inx
    sta 2007
    .endrepeat
    rts

WriteTvAttr:
    ; 23CA
    lda #$23
    sta $2006
    lda #$CA
    sta $2006

    lda #(ST_BOTL | ST_BOTR) & SCREEN_ATTR_TV
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$23
    sta $2006
    lda #$D2
    sta $2006

    lda #(ST_BOTL | ST_BOTR | ST_TOPL | ST_TOPR) & SCREEN_ATTR_TV
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$23
    sta $2006
    lda #$DA
    sta $2006

    lda #(ST_BOTL | ST_BOTR | ST_TOPL | ST_TOPR) & SCREEN_ATTR_TV
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$23
    sta $2006
    lda #$E2
    sta $2006

    lda #(ST_TOPL | ST_TOPR) & SCREEN_ATTR_TV
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    rts

WriteStaticAttributes:
    lda #$27
    sta $2006
    lda #$CA
    sta $2006

    lda #ST_BOTL | ST_BOTR
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$27
    sta $2006
    lda #$D2
    sta $2006

    lda #ST_BOTL | ST_BOTR | ST_TOPL | ST_TOPR
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$27
    sta $2006
    lda #$DA
    sta $2006

    lda #ST_BOTL | ST_BOTR | ST_TOPL | ST_TOPR
    sta $2007
    sta $2007
    sta $2007
    sta $2007

    lda #$27
    sta $2006
    lda #$E2
    sta $2006

    lda #ST_TOPL | ST_TOPR
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    rts

; TODO: This needs to be modified or rewritten.
; Expects pointer to screen data in AddressPointer0 and
; the high byte of the Nametable address in X
LoadScreen:
    asl a
    tay
    lda screen_Index, y
    sta AddressPointer0
    lda screen_Index+1, y
    sta AddressPointer0+1

    bit $2002
    ;lda #$20
    stx $2006
    lda #$00
    sta $2006

@loop:
    ; AddressPointer0 should always point to the
    ; start of a chunk
    ldy #0
    lda (AddressPointer0), y
    tax ; save a copy

    ; get the length of data
    and #$1F
    clc
    adc #1
    sta TmpZ

    ; get the command from the copy
    txa
    and #$E0

    bne @notDone
    rts
@notDone:

    cmp #CHUNK_RLE
    bne :+
    jsr screen_DecodeRLE
    jmp @next
:
    cmp #CHUNK_RAW
    bne :+
    jsr screen_DecodeRAW
    jmp @next
:
    cmp #CHUNK_ADDR
    bne :+
    jsr screen_DecodeADDR
    jmp @next
:
    cmp #CHUNK_SPR
    bne :+
    jsr screen_DecodeSPR
    jmp @next
:
    brk ; Invailid command

@next:
    iny
    ; Get address of next chunk
    tya
    clc
    adc AddressPointer0
    sta AddressPointer0

    lda AddressPointer0+1
    adc #0
    sta AddressPointer0+1

    jmp @loop

screen_DecodeRLE:
    lda TmpZ
    tax
    iny

    and #$01
    beq @even
    ; odd
    lda (AddressPointer0), y
    sta $2007
    dex
    bne @loop
    rts ; there was only one byte of data.  just return

@even:
    lda (AddressPointer0), y
@loop:
    sta $2007
    sta $2007
    dex
    dex
    bne @loop
    rts

screen_DecodeRAW:
    ldx TmpZ

@loop:
    iny
    lda (AddressPointer0), y
    sta $2007
    dex
    bne @loop
    rts

screen_DecodeADDR:
    bit $2002

    iny
    lda (AddressPointer0), y
    sta $2006

    iny
    lda (AddressPointer0), y
    sta $2006

    lda #3
    sta TmpZ
    rts

screen_DecodeSPR:
    iny
    lda (AddressPointer0), y
    sta AddressPointer2

    iny
    lda (AddressPointer0), y
    sta AddressPointer2+1

    tya
    pha

    ldy #0
    ldx #0  ; TODO: load sprites at an offset?

    ; Load number of sprites
    lda (AddressPointer2), y
    sta TmpX
    iny
:
    .repeat 4
    lda (AddressPointer2), y
    sta Sprites, x
    iny
    inx
    .endrepeat

    dec TmpX
    bne :-

    dey
    sty LastSpriteOffset

    pla
    tay
    rts
