; asmsyntax=ca65

TITLE_SpriteTop = 79    ; topmost Y coordinate of cursor
TITLE_MenuLength = 2

Pal_Title:
    .byte $0F, $00, $10, $20

Data_Title_Menu1:
    .byte "Game", $00
Data_Title_Menu2:
    .byte "Credits", $00

Init_Title:
    NMI_Disable

    lda #$00
    sta $2001

    ; Load up a palette
    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006
.repeat 4, i
    lda Pal_Title+i
    sta $2007
.endrepeat

    jsr ClearSprites

    lda #79
    sta Sprites
    lda #100
    sta Sprites+3

    lda #$01    ; tile
    sta Sprites+1
    lda #$00    ; attr
    sta Sprites+2

    jsr WriteSprites

    lda #2
    jsr LoadChrData

    jsr ClearAttrTable0
    lda #$00
    jsr FillNametable0

    ; TODO: Draw a menu
    lda #$21
    sta $2006
    lda #$4E
    sta $2006

    lda #<Data_Title_Menu1
    sta AddressPointer0+0
    lda #>Data_Title_Menu1
    sta AddressPointer0+1
    jsr title_DrawText

    lda #$21
    sta $2006
    lda #$8E
    sta $2006

    lda #<Data_Title_Menu2
    sta AddressPointer0+0
    lda #>Data_Title_Menu2
    sta AddressPointer0+1
    jsr title_DrawText

    lda #0
    sta $2005
    sta $2005

    ; Currently selected item
    sta IdxA

    lda #TITLE_MenuLength
    sta IdxB

    ; Select first nametable
    lda #%10011000
    sta $2000

    lda #%00011110
    sta $2001

    NMI_Set NMI_Title

Frame_Title:
    jsr ReadControllers

    lda #BUTTON_START
    jsr ButtonPressedP1
    beq :+
    lda IdxA
    jsr title_SelectMenuOption
    jmp @button_done

:   lda #BUTTON_A
    jsr ButtonPressedP1
    beq :+
    lda IdxA
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
    sta Sprites+0

    jsr WaitForNMI
    jmp Frame_Title

; Move selection up
t_sel_up:
    dec IdxA
    bpl :+

    ; Wrap around to end
    lda IdxB
    sec
    sbc #1
    sta IdxA

:   rts

; Move selection down
t_sel_down:
    inc IdxA
    lda IdxA
    cmp IdxB
    bcc :+

    ; wrap the index around to zero
    lda #0
    sta IdxA

:   rts


NMI_Title:
    jsr WriteSprites

    dec Sleeping
    rti

; Null terminated string in AddressPointer0, PPU
; address should already be set.
title_DrawText:
    ldy #0
:
    lda (AddressPointer0), y
    beq :+
    sta $2007
    iny
    jmp :-
:
    rts

title_SelectMenuOption:
    ; multiply A by 5
    tay
    ldx data_Mult5, y

    ; grab the address pointer
    lda data_Title+3, x
    sta AddressPointer0
    lda data_Title+4, x
    sta AddressPointer0+1

    ; grab the bank
    lda data_Title+2, x

    ; do a long jump
    jmp LongJump
    rts

data_Title:
    ; Tile start ID, length, bank, init pointer
    .byte $00, 0, 0
        .word Init_Game
    .byte $00, 0, 13
        .word Init_Credits

data_Mult5:
.repeat 10, i
    .byte (i * 5)
.endrepeat
