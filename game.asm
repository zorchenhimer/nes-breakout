; asmsyntax=ca65

Pal_Game:
    .byte $0F, $0A, $1A, $2A

Pal_GameSprites:
    .byte $0F, $07, $17, $27

Init_Game:
    NMI_Disable

    ; Disable drawing BG and sprites
    lda #$00
    sta $2001

    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    ; Load up a palette
.repeat 4, i
    lda Pal_Game+i
    sta $2007
.endrepeat

    lda #$3F
    sta $2006
    lda #$10
    sta $2006

    ; Load up another palette
.repeat 4, i
    lda Pal_GameSprites+i
    sta $2007
.endrepeat

    lda #0
    jsr FillNametable2
    jsr ClearAttrTable0

    lda #1
    jsr LoadChrData

    jsr ClearSprites

    ; Y, X
    lda #$80
    sta Sprites+4
    sta Sprites+7

    ; Tile
    lda #$10
    sta Sprites+5

    ; Attributes
    lda #0
    sta Sprites+6

    jsr WriteSprites

    ; Draw top two rows
    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda #$01
    ldx #64
:
    sta $2007
    dex
    bne :-

    ; draw bottom two rows
    lda #$23
    sta $2006
    lda #$80
    sta $2006

    lda #$01
    ldx #64
:
    sta $2007
    dex
    bne :-

    ; Draw Left
    lda #%10011100
    sta $2000

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda #$01
    ldx #30
:
    sta $2007
    dex
    bne :-

    ; Draw Right
    lda #$20
    sta $2006
    lda #$1F
    sta $2006

    lda #$01
    ldx #30
:
    sta $2007
    dex
    bne :-

    ; Sprite zero
    ; TODO: Try to change the background color
    ; during H-Blank with this as the trigger
    lda #247
    sta Sprites+3
    lda #120
    sta Sprites+0

    lda #0
    sta Sprites+1
    lda #1
    sta Sprites+2

    lda #$00
    sta BallX
    sta BallY

    lda #$80
    sta BallX+1
    lda #$70
    sta BallY+1

    ; Select first nametable
    lda #%10011000
    sta $2000

    lda #%00011110
    sta $2001

    lda #$00
    sta $2005
    sta $2005

    NMI_Set NMI_Game

AccelSpeed = 1

Frame_Game:
    jsr ReadControllers

    lda #BUTTON_UP
    and controller1
    ;jsr ButtonPressedP1
    beq :+

    ; Move ball up
    lda BallSpeedY
    sec
    sbc #AccelSpeed
    sta BallSpeedY

    lda BallSpeedY+1
    sbc #0
    sta BallSpeedY+1
:

    lda #BUTTON_DOWN
    ;jsr ButtonPressedP1
    and controller1
    beq :+

    ; Move ball down
    lda BallSpeedY
    clc
    adc #AccelSpeed
    sta BallSpeedY

    lda BallSpeedY+1
    adc #0
    sta BallSpeedY+1
:

    lda #BUTTON_LEFT
    and controller1
    beq :+

    lda BallSpeedX
    sec
    sbc #AccelSpeed
    sta BallSpeedX

    lda BallSpeedX+1
    sbc #0
    sta BallSpeedX+1
:

    lda #BUTTON_RIGHT
    and controller1
    beq :+

    lda BallSpeedX
    clc
    adc #AccelSpeed
    sta BallSpeedX

    lda BallSpeedX+1
    adc #0
    sta BallSpeedX+1
:
    jsr UpdateBallCoords
    jsr WaitForNMI
    jmp Frame_Game

NMI_Game:
    jsr WriteSprites
    dec Sleeping
    rti

; Read BallX and BallY coords and translate
; them to sprite coords
UpdateBallCoords:
    ; Update coords in memory using the speeds
    lda BallX
    clc
    adc BallSpeedX
    sta BallX

    lda BallX+1
    adc BallSpeedX+1
    sta BallX+1

@vertical:
    lda BallY
    clc
    adc BallSpeedY
    sta BallY

    lda BallY+1
    adc BallSpeedY+1
    sta BallY+1

    ; Update sprite coordinates
    lda BallX+1
    sec
    sbc #4
    sta Sprites+7

    lda BallY+1
    sec
    sbc #4
    sta Sprites+4
    rts
