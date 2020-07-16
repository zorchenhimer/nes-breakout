; asmsyntax=ca65

.importzp main_NUMBER_OF_MAPS

TITLE_SpriteTop = 79    ; topmost Y coordinate of cursor
TitleCursorTile = $1D

Title_TextChrIdStart = $20
Title_TextChrAddrStart = Title_TextChrIdStart * 16
Title_TextLength = 12
Title_TextRowCount = 2

Init_Title:
    .NMI_Disable
    .Disable_Drawing

    ; Load up a palette
.repeat 8, i
    lda Pal_Tv+i
    sta PaletteBuffer+i
    sta PaletteBufferSprites+i
.endrepeat

    ; Unused palettes.  Make them red.
;    lda #$16
;.repeat 4, i
;    sta PaletteBuffer+8+i
;    sta PaletteBufferSprites+8+i
;.endrepeat

    jsr ClearRam
    jsr ClearSprites

    lda #$0F
    sta CurrentBoard

    lda #2
    jsr LoadChrData

    lda #7
    jsr LoadChrData

    jsr ClearAttrTable0
    ;lda #$0F
    ;jsr FillNametable0

    jsr WriteTvAttr

    lda #ScreenIDs::Tv
    ldx #$20
    jsr LoadScreen

    ; Draw a menu
    lda #$21
    sta AddressPointer0+1
    lda #$4A
    sta AddressPointer0+0

    ldx LastSpriteOffset
    lda #79
    sta Sprites, x
    lda #70
    sta Sprites+3, x

    lda #TitleCursorTile    ; tile
    sta Sprites+1, x
    lda #$00    ; attr
    sta Sprites+2, x

    ; Draw two rows for the menu text.
    ldy #Title_TextChrIdStart
    ldx #0
    stx TmpX    ; rows
@textTileLoop:
    ; CHR start address for the text
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ; Calculate the next start address
    clc
    adc #64
    sta AddressPointer0+0

    lda AddressPointer0+1
    adc #0
    sta AddressPointer0+1

    ldx #0      ; colums
:
    sty $2007
    iny
    inx
    cpx #Title_TextLength
    bne :-

    inc TmpX
    lda TmpX
    cmp #Title_TextRowCount
    bne @textTileLoop

    ldx #0
    ldy #0
    sty TmpX
@menuLoop:

    txa
    pha
    jsr title_DrawText
    pla
    tax
    inc TmpX

    ; Read the init index
    iny
    lda data_TitleMenu, y
    sta title_MenuItems, x
    inx
    stx title_MenuLength

    ; Check for next item
    iny
    lda data_TitleMenu, y

    beq @menuDone
    jmp @menuLoop
@menuDone:
    jsr WaitForNMI

    lda #0
    sta $2005
    sta $2005

    sta ls_PrevTraceCount

    ; Currently selected item
    sta IdxA

    lda #$0F
    sta menu_PrevLevel

    lda #3
    sta LivesCount
    jsr ReadControllers

    .NMI_Set NMI_Title

Frame_Title:
    jsr ReadControllers

    lda #BUTTON_START
    jsr ButtonPressedP1
    beq :+
    jmp title_SelectMenuOption
    jmp @button_done

:   lda #BUTTON_A
    jsr ButtonPressedP1
    beq :+
    jmp title_SelectMenuOption
    jmp @button_done

:   lda #BUTTON_UP
    jsr ButtonPressedP1
    beq :+
    jsr t_sel_up
    jmp @button_done

:   lda #BUTTON_DOWN
    jsr ButtonPressedP1
    beq :+
    jsr t_sel_down
    jmp @button_done

:   lda #BUTTON_SELECT
    jsr ButtonPressedP1
    beq :+
    jsr t_sel_down
:

@button_done:
    ; calculate Y for cursor
    lda IdxA
    asl a
    asl a
    asl a
    asl a
    clc
    adc #TITLE_SpriteTop
    ldx LastSpriteOffset
    sta Sprites+0, x

    jsr WaitForNMI
    jmp Frame_Title

; Move selection up
t_sel_up:
    dec IdxA
    bpl :+

    ; Wrap around to end
    lda title_MenuLength
    sec
    sbc #1
    sta IdxA

:   rts

; Move selection down
t_sel_down:
    inc IdxA
    lda IdxA
    cmp title_MenuLength
    bcc :+

    ; wrap the index around to zero
    lda #0
    sta IdxA

:   rts


NMI_Title:
    ; Select first nametable
    jsr WritePalettes
    jsr WriteSprites

    lda #%10000000
    sta $2000

    lda #%00011110
    sta $2001

    .SetScroll $00

    dec Sleeping
    rti

; Null terminated string in AddressPointer0, PPU
; address should already be set.
title_DrawText:
    jsr TextClearStringBuffer

    ldx #0
    lda #0
:
    sta TextBuffer, x
    inx
    cpx #12
    bne :-

    ;ldy #0
    ldx #0
:
    lda data_TitleMenu, y
    beq :+
    sta TextBuffer, x
    inx
    iny
    jmp :-
:

    tya
    pha
    jsr TextPrepare

    lda TmpX
    beq @firstRow
    ; Second row
    lda #$C0
    sta AddressPointer0+0
    lda #$02
    sta AddressPointer0+1

    jmp @end

@firstRow:
    lda #$00
    sta AddressPointer0+0
    lda #$02
    sta AddressPointer0+1

@end:
    ;pla ; number of tiles to write
    lda #12
    jsr WriteTextBuffer

    pla
    tay
    rts

title_SelectMenuOption:
    lda CurrentBoard
    sta menu_PrevLevel

    .NMI_Disable
    jsr WaitForNMI

    ldx IdxA
    lda title_MenuItems, x
    jmp JumpToInit

; Text is null terminated
data_TitleMenu:
    .byte "Level Select", $00, InitIDs::LevelSelect
    .byte "Credits", $00, InitIDs::Credits
    .byte $00


title_PalBackground:
    .byte $0F, $11, $14, $1B

    nop
    nop

