; asmsyntax=ca65

.importzp main_NUMBER_OF_MAPS

TITLE_SpriteTop = 79    ; topmost Y coordinate of cursor
;TITLE_MenuLength = 3

Pal_Title:
    .byte $0F, $00, $10, $20

Init_Title:
    .NMI_Disable
    .Disable_Drawing

    ; Load up a palette
.repeat 4, i
    lda Pal_Title+i
    sta PaletteBuffer+i
    sta PaletteBufferSprites+i
.endrepeat

    jsr Clear_NonGlobalRam
    jsr ClearSprites

    lda #79
    sta Sprites
    lda #100
    sta Sprites+3

    lda #$01    ; tile
    sta Sprites+1
    lda #$00    ; attr
    sta Sprites+2

    lda #20
    sta Sprites+4
    sta Sprites+7

    lda #$00
    sta Sprites+6 ; attr

    lda #$80
    sta Sprites+5 ; tile

    lda #0
    sta CurrentBoard

    ;jsr WriteSprites

    lda #2
    jsr LoadChrData

    lda #3
    jsr LoadChrData

    jsr ClearAttrTable0
    lda #$00
    jsr FillNametable0

    ; Draw a menu
    lda #$21
    sta AddressPointer0+1
    lda #$4E
    sta AddressPointer0+0

    ldx #0
    ldy #0
@menuLoop:
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    clc
    adc #64
    sta AddressPointer0+0

    lda AddressPointer0+1
    adc #0
    sta AddressPointer0+1

    jsr title_DrawText

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

    ; Currently selected item
    sta IdxA

    ;lda #TITLE_MenuLength
    ;sta IdxB

    .NMI_Set NMI_Title

Frame_Title:
    jsr ReadControllers

    lda #BUTTON_START
    jsr ButtonPressedP1
    beq :+
    jsr title_SelectMenuOption
    jmp @button_done

:   lda #BUTTON_A
    jsr ButtonPressedP1
    beq :+
    jsr title_SelectMenuOption
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

:   lda #BUTTON_LEFT
    jsr ButtonPressedP1
    beq :+
    dec CurrentBoard
    bpl :+
    lda #main_NUMBER_OF_MAPS
    sec
    sbc #1
    sta CurrentBoard

:   lda #BUTTON_RIGHT
    jsr ButtonPressedP1
    beq :+
    inc CurrentBoard
    lda CurrentBoard
    cmp #main_NUMBER_OF_MAPS
    bcc :+
    lda #0
    sta CurrentBoard
:
    lda CurrentBoard
    ora #$80
    sta Sprites+5

@button_done:
    ; calculate Y for cursor
    lda IdxA
    asl a
    asl a
    asl a
    asl a
    clc
    adc #TITLE_SpriteTop
    sta Sprites+0

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

    lda #%10011000
    sta $2000

    lda #%00011110
    sta $2001

    .SetScroll $00

    dec Sleeping
    rti

; Null terminated string in AddressPointer0, PPU
; address should already be set.
title_DrawText:
    ;ldy #0
:
    lda data_TitleMenu, y
    beq :+
    sta $2007
    iny
    jmp :-
:
    rts

title_SelectMenuOption:
    .NMI_Disable
    jsr WaitForNMI

    ldx IdxA
    lda title_MenuItems, x
    jmp JumpToInit

data_TitleMenu:
    .byte "Start", $00, 1
    .byte "Level Select", $00, 3
    .byte "Credits", $00, 2
    .byte $00

title_PalBackground:
    .byte $0F, $11, $14, $1B
