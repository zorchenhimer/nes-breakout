; asmsyntax=ca65

Init_Title:
    NMI_Disable

    lda #$00
    sta $2001

    jsr ClearSprites
    jsr WriteSprites

    ; TODO: palletes

    jsr ClearAttrTable0
    lda #$00
    jsr FillNametable0

    ; TODO: Draw a menu

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

    lda #0
    jmp title_SelectMenuOption
:

    lda #BUTTON_SELECT
    jsr ButtonPressedP1
    beq :+

    lda #1
    jmp title_SelectMenuOption
:

    jsr WaitForNMI
    jmp Frame_Title

NMI_Title:
    dec Sleeping
    rti

title_SelectMenuOption:
    ; multiply A by 5
    tay
    ldx data_Mult5, y

    ; grab the address pointer
    lda data_Title+2, x
    sta AddressPointer0
    lda data_Title+3, x
    sta AddressPointer0+1

    ; grab the bank
    lda data_Title+4, x

    ; do a long jump
    jmp LongJump
    rts

data_Title:
    ; Tile start ID, length, init pointer, bank
    .byte $00, 0, .lobyte(Init_Game), .hibyte(Init_Game), 0
    .byte $00, 0, .lobyte(Init_Credits), .hibyte(Init_Credits), 13

data_Mult5:
.repeat 10, i
    .byte (i * 5)
.endrepeat
