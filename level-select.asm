; asmsyntax=ca65

ls_PalStack:
    .byte $0F, $0F, $20, $20

ls_PalCables:
    .byte $0F, $12, $1A, $16

data_ls_BGPalettes:
    .byte $0F, $19, $2A, $09
    .byte $0F, $39, $0F, $09
    .byte $0F, $00, $10, $30

    nop
    nop

; Intial load of palettes
ls_LoadPalettes:
    ldx #0
@stack:
    lda ls_PalStack, x
    sta PaletteBufferSprites, x
    inx
    cpx #4
    bne @stack

    ; background palettes
    ldx #0
:
    lda data_ls_BGPalettes, x
    sta PaletteBuffer, x
    inx
    cpx #12
    bne :-

; TODO: Read this from the animation data
    lda #1
    ldx #7
:
    sta ls_PaletteFrameTimer, x
    dex
    bpl :-

; cable palette
    ldx #0
    ldy #8
:
    lda ls_PalCables, x
    sta PaletteBufferSprites, y
    iny
    inx
    cpx #4
    bne :-
    rts

Init_LevelSelect:
    .NMI_Disable
    .Disable_Drawing

    jsr MMC1_Select_Vert

    jsr Clear_NonGlobalZp
    jsr ClearSprites

    jsr ls_LoadPalettes

    jsr ClearAttrTable0
    jsr ClearAttrTable1

    lda #ChrData::LevelSelect
    jsr LoadChrData

    lda #ChrData::LevelSelectUi
    jsr LoadChrData

    bit $2000

    lda #$22
    sta $2006
    lda #$60
    sta $2006

    ; Draw a line above the box
    lda #$FD
    ldx #32
:
    sta $2007
    dex
    bne :-

    ; draw a box for the bottom non-map portion
    ldx #32
    ldy #10
    lda #$FE
:
    sta $2007
    dex
    bne :-
    ldx #32
    dey
    bne :-

    lda #$26
    sta $2006
    lda #$60
    sta $2006

    ldx #32
    lda #$FD
:
    sta $2007
    dex
    bne :-

    ; Draw a column on the right side of the bottom
    lda #$22
    sta $2006
    lda #$9F
    sta $2006

    .Update_PpuControl PPU_CTRL_VERTICAL
    lda #$FF
    ldx #10
:
    sta $2007
    dex
    bne :-

    ;.Update_PpuControl PPU_CTRL_NMI
    .Update_PpuControl 0

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    ; Draw the background
    ldx #0
:
    lda data_LS_BackgroundA, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundA+256, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundA+512, x
    sta $2007
    inx
    cpx #128
    bne :-

    lda #$24
    sta $2006
    lda #$00
    sta $2006

    ; Draw the second background
    ldx #0
:
    lda data_LS_BackgroundB, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundB+256, x
    sta $2007
    inx
    bne :-

:
    lda data_LS_BackgroundB+512, x
    sta $2007
    inx
    cpx #128
    bne :-

    ; Draw the level icons
    lda #0
    sta menu_DrawnSprites

    jsr ls_LoadSprites

    ; Setup sprite zero
    lda #$FD
    sta Sprites+1

    lda #$C0 ;x
    sta Sprites+3
    lda #151 ;y
    sta Sprites+0

    lda #0
    sta Sprites+2

    ; Load up current selection data
    lda menu_PrevLevel
    asl a
    tax

    lda data_Level_Progression_Idx, x
    sta ls_LevelProg
    lda data_Level_Progression_Idx+1, x
    sta ls_LevelProg+1

    ; load data into cursor section stuff
    ldy #0
    ldx #0
    stx ls_NumActiveLevels
:
    lda (ls_LevelProg), y
    bmi :+
    sta ls_ActiveLevels, x
    inc ls_NumActiveLevels
    inx
    iny
    jmp :-
:

    lda #LS_CURSOR_ANIM_FRAMES
    sta ls_cursorAnim
    lda #LS_CURSOR_COLOR_START
    sta ls_cursorColorBuff

    ; Light up previous traces
    lda #0
    sta TmpW
    lda ls_PrevTraceCount
    beq @noPrevTraces
    sta IdxB
@prevTraceLoop:
    lda TmpW
    asl a
    tax

    inc TmpW

    lda ls_PrevTraces, x
    sta AddressPointer1
    lda ls_PrevTraces+1, x
    sta AddressPointer1+1

    jsr ls_LightGivenTrace
    jsr ls_WriteTraceAttr

    lda AddressPointer2
    sta ls_PrevTraceAddr
    lda AddressPointer2+1
    sta ls_PrevTraceAddr+1

    lda IdxD
    sta ls_PrevTraceData

    dec IdxB
    bne @prevTraceLoop

@noPrevTraces:
    lda #0
    sta ls_SelectedLevel
    jsr ls_LightTrace

    jsr ls_LoadCursor

; Draw bottom UI
    lda #$22
    sta $2006
    lda #$80
    sta $2006

    ;ldy data_ls_ui2_len
    ;lda data_LS_Ui_Len+0
    ;sta AddressPointer0+0
    ;lda data_LS_Ui_Len+1
    ;sta AddressPointer0+1

    lda #<data_LS_Ui
    sta AddressPointer1+0
    lda #>data_LS_Ui
    sta AddressPointer1+1

    ldy #0
@uiLoop:
    lda (AddressPointer1), y
    cmp #$FF
    beq @uiDone
    sta $2007

    ; increment pointer
    inc AddressPointer1
    bne :+
    inc AddressPointer1+1
:

    jmp @uiLoop
@uiDone:

    ; Attributes for the bottom
    lda #$23
    sta $2006
    lda #$E8
    sta $2006

    ldy #data_LS_Ui_Attr_Len
    ldx #0
:
    lda data_LS_Ui_Attr, x
    sta $2007
    inx
    dey
    bne :-

    ; Level title
    lda #$22
    sta $2006
    lda #$C6
    sta $2006

    ldx #$B0
:
    stx $2007
    inx
    cpx #$B8
    bne :-

    ; Level text, line one
    lda #$23
    sta $2006
    lda #$06
    sta $2006

    ldx #$B8
:
    stx $2007
    inx
    cpx #$C8
    bne :-

    ; Level text, line two
    lda #$23
    sta $2006
    lda #$26
    sta $2006

    ldx #$C8
:
    stx $2007
    inx
    cpx #$D8
    bne :-

    lda #$26
    sta $2006
    lda #$80
    sta $2006

    lda #$FE
    ldy #10
:
    .repeat 32
    sta $2007
    .endrepeat
    dey
    bne :-

    lda #1
    sta ls_WriteText

    ; title text
    jsr ls_PrepLevelText
    jsr ls_WriteTextTiles
    ;lda #$1B
    ;sta AddressPointer0+1
    ;lda #$00
    ;sta AddressPointer0+0
    ;lda #8
    ;jsr WriteTextBuffer_LevelSelect_8

    ; line 1 text
    jsr ls_PrepLevelText
    jsr ls_WriteTextTiles
    jsr ls_WriteTextTiles
    ;lda #$1B
    ;sta AddressPointer0+1
    ;lda #$80
    ;sta AddressPointer0+0
    ;lda #16
    ;jsr WriteTextBuffer_LevelSelect_15

    ; line 2 text
    jsr ls_PrepLevelText
    jsr ls_WriteTextTiles
    jsr ls_WriteTextTiles
    ;lda #$1C
    ;sta AddressPointer0+1
    ;lda #$80
    ;sta AddressPointer0+0
    ;lda #16
    ;jsr WriteTextBuffer_LevelSelect_15

    lda #0
    sta ls_WriteText

    ; Draw the cable sprites on the right
LSCABLE_YSTART = 160
LSCABLE_XSTART = 226
    ;ldx #4 * 6  ; destination offset
    ldx #2   ; attr
    .repeat 4, i
    lda #LSCABLE_YSTART
    sta Sprites+(5*4)+(i*4)+0
    lda #$B0 + i
    sta Sprites+(5*4)+(i*4)+1
    stx Sprites+(5*4)+(i*4)+2
    lda #LSCABLE_XSTART + (i * 8)
    sta Sprites+(5*4)+(i*4)+3
    .endrepeat

    .repeat 4, i
    lda #LSCABLE_YSTART+8
    sta Sprites+(9*4)+(i*4)+0
    lda #$B4 + i
    sta Sprites+(9*4)+(i*4)+1
    stx Sprites+(9*4)+(i*4)+2
    lda #LSCABLE_XSTART + (i * 8)
    sta Sprites+(9*4)+(i*4)+3
    .endrepeat

    .repeat 4, i
    lda #LSCABLE_YSTART+16
    sta Sprites+(13*4)+(i*4)+0
    lda #$B8 + i
    sta Sprites+(13*4)+(i*4)+1
    stx Sprites+(13*4)+(i*4)+2
    lda #LSCABLE_XSTART + (i * 8)
    sta Sprites+(13*4)+(i*4)+3
    .endrepeat

    .repeat 4, i
    lda #LSCABLE_YSTART+24
    sta Sprites+(17*4)+(i*4)+0
    lda #$BC + i
    sta Sprites+(17*4)+(i*4)+1
    stx Sprites+(17*4)+(i*4)+2
    lda #LSCABLE_XSTART + (i * 8)
    sta Sprites+(17*4)+(i*4)+3
    .endrepeat

    ldx #$42   ; attr
    .repeat 4, i
    lda #LSCABLE_YSTART+(8*4)+(i*8)-3
    sta Sprites+(21*4)+(i*4)+0
    lda #$B0 + (i * 4)
    sta Sprites+(21*4)+(i*4)+1
    stx Sprites+(21*4)+(i*4)+2
    lda #3
    sta Sprites+(21*4)+(i*4)+3
    .endrepeat

    lda #1
    sta ls_SpinnerCount
    lda #0
    sta ls_SpinnerFlip

    ;jsr ls_PrepLevelText

    jsr TextClearBuffer
    jsr TextClearStringBuffer

    .NMI_Set NMI_LevelSelect
    .Update_PpuControl PPU_CTRL_NMI
    jsr WaitForNMI

    lda #1
    sta ls_WriteText

Frame_LevelSelect:
    lda #0
    sta TmpZ
    jsr ls_AnimateSpinner

    jsr ReadControllers

    lda #BUTTON_RIGHT
    jsr ButtonPressedP1
    beq :+
    lda #1
    sta ls_WriteText

    lda ls_SelectedLevel
    sta ls_SelectedLevel_Prev
    inc ls_SelectedLevel
    inc TmpZ
    jmp @incOver
:
    lda #BUTTON_DOWN
    jsr ButtonPressedP1
    beq :+
    lda #1
    sta ls_WriteText

    lda ls_SelectedLevel
    sta ls_SelectedLevel_Prev
    inc ls_SelectedLevel
    inc TmpZ
:

@incOver:
    ; handle overflow
    lda ls_SelectedLevel
    cmp ls_NumActiveLevels
    bne :+
    lda #0
    sta ls_SelectedLevel
:

    lda #BUTTON_LEFT
    jsr ButtonPressedP1
    beq :+
    lda #1
    sta ls_WriteText

    lda ls_SelectedLevel
    sta ls_SelectedLevel_Prev
    dec ls_SelectedLevel
    inc TmpZ
    jmp @decUnder
:
    lda #BUTTON_UP
    jsr ButtonPressedP1
    beq :+
    lda #1
    sta ls_WriteText

    lda ls_SelectedLevel
    sta ls_SelectedLevel_Prev
    dec ls_SelectedLevel
    inc TmpZ
:

@decUnder:
    ; handle underflow
    lda ls_SelectedLevel
    bpl :+
    lda ls_NumActiveLevels
    sec
    sbc #1
    sta ls_SelectedLevel
:

    ; Don't inc/dec selection for first level
    lda menu_PrevLevel
    cmp #$0F
    bne :+
    lda #0
    sta ls_SelectedLevel
:

    ; Write trace attributes if selection changed
    lda TmpZ
    beq :+
    jsr ls_ResetTrace
    jsr ls_LightTrace
:

    jsr ls_LoadCursor
    lda ls_WriteText
    beq :+
    jsr ls_PrepLevelText
:

    lda #BUTTON_A
    jsr ButtonPressedP1
    beq :+
    jmp ls_StartLevel
:

    lda #BUTTON_START
    jsr ButtonPressedP1
    beq :+
    jmp ls_StartLevel
:

    ; On select, got to a "Map View" mode
    lda #BUTTON_SELECT
    jsr ButtonPressedP1
    beq :+

    jsr WaitForSpriteZero
    lda #0
    sta $2005
    sta $2005

    lda #PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN
    sta $2000
    jsr WaitForNMI
    jsr ls_DoAnimations
    jmp Frame_LevelSelect_ViewMap
:

    jsr WaitForSpriteZero
    lda #0
    sta $2005
    sta $2005

    lda #PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN
    sta $2000

    jsr ls_DoAnimations

    ;jsr TextClearBuffer

    jsr WaitForNMI
    jmp Frame_LevelSelect

Frame_LevelSelect_ViewMap:
    jsr ReadControllers

    lda controller1
    and #BUTTON_LEFT
    beq :+
    lda menu_ScrollValue
    beq :+
    dec menu_ScrollValue
:

    lda controller1
    and #BUTTON_RIGHT
    beq :+
    lda menu_ScrollValue
    cmp #$FF
    beq :+
    inc menu_ScrollValue
:

    ; Go back to the main menu on SELECT
    lda #BUTTON_SELECT
    jsr ButtonPressedP1
    beq :+

    jsr ls_DrawCursorXY
    jsr ls_DoAnimations

    jsr WaitForSpriteZero
    lda #0
    sta $2005
    sta $2005

    lda #PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN
    sta $2000

    jsr WaitForNMI
    jmp Frame_LevelSelect
:

    ldx #11
    ldy #10
    lda #228
    sta TmpX
    lda #139
    sta TmpY

    jsr ls_DrawCursorXY
    jsr ls_DoAnimations

    jsr WaitForSpriteZero
    lda #0
    sta $2005
    sta $2005

    lda #PPU_CTRL_NMI | PPU_CTRL_BG_PATTERN
    sta $2000

    jsr WaitForNMI
    jmp Frame_LevelSelect_ViewMap

ls_StartLevel:
    ; Skip previous traces if previous level is $0F or $00
    lda menu_PrevLevel
    cmp #$0F
    beq :+

    ; Save the selected trace's data pointer
    ; so we can relight it later
    lda ls_PrevTraceCount
    asl a
    tax

    lda ls_TmpTracePointer
    sta ls_PrevTraces, x
    lda ls_TmpTracePointer+1
    sta ls_PrevTraces+1, x
    inc ls_PrevTraceCount
:

    ldx ls_SelectedLevel
    lda ls_ActiveLevels, x
    sta CurrentBoard
    jsr WaitForNMI
    lda #1
    jmp JumpToInit

ls_DoAnimations:
    ; Cursor palette animation
    dec ls_cursorAnim
    bne @noCursorAnim
    lda #LS_CURSOR_ANIM_FRAMES
    sta ls_cursorAnim

    inc ls_cursorColorBuff
    lda ls_cursorColorBuff
    cmp #LS_CURSOR_COLOR_END
    bne :+
    lda #LS_CURSOR_COLOR_START
    sta ls_cursorColorBuff
:
@noCursorAnim:

    lda #0
    sta menu_LoadedSprites
    sta menu_DrawnSprites
    sta IdxA

; Load visible sprite animations
;    ;.repeat SPRITE_OBJ_COUNT, count
;    .repeat 11, count
;    lda #count
;    jsr ls_SpriteAnimate
;    .endrepeat
@animLoop:
    lda IdxA
    jsr ls_SpriteAnimate

    ;lda IdxA
    ;jsr ls_SpriteScroll

    inc IdxA
    lda IdxA
    cmp #SPRITE_OBJ_COUNT
    bne @animLoop

; scroll animation sprites
;    ldx #0
;    stx IdxA
;@scrollLoop:
;    lda IdxA
;    jsr ls_SpriteScroll
;
;    inc IdxA
;    lda IdxA
;    cmp menu_LoadedSprites
;    bne @scrollLoop

    ; sprite ID -> offset
    lda menu_DrawnSprites
    clc
    adc #LEVELSELECT_SPRITE_OFFSET
    asl a
    asl a
    tax

    lda #$FF
:
    sta Sprites, x
    inx
    bne :-

; Animate all palettes
    ldx #0
    stx IdxA
@palLoop:
    lda IdxA
    jsr ls_PaletteAnimate

    inc IdxA
    lda IdxA
    cmp #PAL_ANIM_COUNT
    bne @palLoop
    rts

tr_frames:
    ; scroll the screen
    ; move the cursor offset

    ; find offset between two steps
    ; move cursor one step per frame
    ; ignore all input during animation
    ; animate other sprites during this transition

    jsr ls_DoAnimations
    jsr ls_StepCursor
    jsr WaitForNMI

    jmp Frame_LevelSelect

ls_StepCursor:
    rts

NMI_LevelSelect:
    pha
    txa
    pha
    tya
    pha

    jsr WritePalettes

    .WriteSprites

    lda ls_AttrUpdate
    ora ls_AttrUpdate_Clr
    beq :+
    jsr ls_WriteTraceAttr
:

    jsr ls_WriteTextTiles

    ;.SetScroll_Var 0
    ; TODO: nametable
    bit $2000

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    lda menu_ScrollValue
    sta $2005
    lda #0
    sta $2005

    .Update_PpuControl PPU_CTRL_NMI
    .Update_PpuMask PPU_MASK_ON

    lda #$FF
    sta Sleeping

    pla
    tay
    pla
    tax
    pla
    rti

ls_WriteTextTiles:
    lda #0
    sta $2001

    ldx ls_WriteText
    beq @noWrite

    dex
    lda ls_writeTilesJmp_Lo, x
    sta AddressPointer0+0
    lda ls_writeTilesJmp_Hi, x
    sta AddressPointer0+1
    jmp (AddressPointer0)

@noWrite:
    rts

ls_writeTiles_Title:
    lda #$1B
    sta AddressPointer0+1
    lda #$00
    sta AddressPointer0+0
    jsr WriteTextBuffer_LevelSelect_8
    jmp ls_writeTiles_done

ls_writeTiles_Line1a:
    lda #$1B
    sta AddressPointer0+1
    lda #$80
    sta AddressPointer0+0
    jsr WriteTextBuffer_LevelSelect_8
    jmp ls_writeTiles_done

ls_writeTiles_Line1b:
    lda #$1C
    sta AddressPointer0+1
    lda #$00
    sta AddressPointer0+0
    jsr WriteTextBuffer_LevelSelect_7
    jmp ls_writeTiles_done

ls_writeTiles_Line2a:
    lda #$1C
    sta AddressPointer0+1
    lda #$80
    sta AddressPointer0+0
    jsr WriteTextBuffer_LevelSelect_8
    jmp ls_writeTiles_done

ls_writeTiles_Line2b:
    lda #$1D
    sta AddressPointer0+1
    lda #$00
    sta AddressPointer0+0
    jsr WriteTextBuffer_LevelSelect_7
    jmp ls_writeTiles_done

ls_writeTiles_done:
    inc ls_WriteText
    lda ls_WriteText
    cmp #6
    bne :+
    lda #0
    sta ls_WriteText
    sta IgnoreInput
:
    rts

ls_writeTilesJmp_Hi:
    .byte .hibyte(ls_writeTiles_Title)
    .byte .hibyte(ls_writeTiles_Line1a)
    .byte .hibyte(ls_writeTiles_Line1b)
    .byte .hibyte(ls_writeTiles_Line2a)
    .byte .hibyte(ls_writeTiles_Line2b)

ls_writeTilesJmp_Lo:
    .byte .lobyte(ls_writeTiles_Title)
    .byte .lobyte(ls_writeTiles_Line1a)
    .byte .lobyte(ls_writeTiles_Line1b)
    .byte .lobyte(ls_writeTiles_Line2a)
    .byte .lobyte(ls_writeTiles_Line2b)

; jsr to AddressPointer0
JsrPointer:
    lda #>@end-1
    pha
    lda #<@end-1
    pha

    jmp (AddressPointer0)

@end:
    rts

; PPU Address in AddressPointer0
; Width of tiles in TmpX
; Height of tiles in TmpY
; Tile ID start in TmpW
ls_DrawLevelIcon:
    ;ldy TmpY
@row:
    lda AddressPointer0+1
    sta $2006
    lda AddressPointer0+0
    sta $2006

    ldy TmpW
    ldx TmpX
@col:
    sty $2007
    iny
    dex
    bne @col

    dec TmpY
    beq @done

    ; Get the start ID of the next tile row
    lda TmpW
    clc
    adc #16
    sta TmpW
    tay

    ; Increment address to next row
    lda AddressPointer0
    clc
    adc #32
    sta AddressPointer0

    bcc :+
    inc AddressPointer0+1
:
    jmp @row

@done:
    rts

; Animate palettes
; Palette animation index in A
ls_PaletteAnimate:
    asl a
    tax
    lda data_PaletteAnim_List+0, x
    sta AddressPointer0+0
    lda data_PaletteAnim_List+1, x
    sta AddressPointer0+1

    ldy #0
    ; Palette Index
    lda (AddressPointer0), y
    tax
    asl a
    asl a
    sta TmpY

    dec ls_PaletteFrameTimer, x
    bne @noAnim

    inc ls_PaletteFrames, x
    lda ls_PaletteFrames, x

    ; check for overflow
    ldy #1
    cmp (AddressPointer0), y
    bcc :+
    lda #0
    sta ls_PaletteFrames, x
:

    iny
    lda (AddressPointer0), y
    sta ls_PaletteFrameTimer, x

@noAnim:
    lda ls_PaletteFrames, x
    asl a
    asl a
    clc
    adc #3
    tay

    ldx #0
:
    lda (AddressPointer0), y
    sta ls_PalTmp, x
    iny
    inx
    cpx #4
    bne :-

    ldy TmpY    ; reload palette offset
    ldx #0
:
    lda ls_PalTmp, x
    sta PaletteBuffer, y
    iny
    inx
    cpx #4
    bne :-

    rts

; Sprite ID in a
; Read the sprite data from RAM, manipulate the
; coords, and write it to OAM if it is on screen.
ls_SpriteScroll:
    ldx menu_LoadedSprites
    ;dex
    ;tax
    lda ls_SpriteFlags, x
    and #$08
    bne @nt2check
    ; First nametable
    lda ls_SpriteX, x
    sec
    sbc menu_ScrollValue
    bcs @drawOk
    ; Off the left side of the screen; don't draw.
    rts
@drawOk:
    sta TmpX
    lda menu_DrawnSprites
    clc
    ; increment past sprite zero and cursor sprites
    adc #LEVELSELECT_SPRITE_OFFSET
    asl a
    asl a
    tay
    ;sta TmpZ    ; Sprite offset in OAM
    lda ls_SpriteY, x
    sta Sprites, y
    iny

    lda ls_SpriteTiles, x
    sta Sprites, y
    iny

    ; Palette is in lower two bits
    lda ls_SpriteFlags, x
    ;and #$03
    sta Sprites, y
    iny

    lda TmpX
    sta Sprites, y

    inc menu_DrawnSprites
    rts

@nt2check:
    lda ls_SpriteX, x
    sec
    sbc menu_ScrollValue
    bcc @drawOk
    rts

; Initial sprite loading stuff
; Loads the frame rate info into RAM
ls_LoadSprites:
    ldx #0
:
    ; frame rate.  Start at 1 so every sprite is
    ; updated on the first call to ls_SpriteAnimate.
    lda #1
    sta ls_SpriteFrameTimer, x
    inx

    cpx #SPRITE_OBJ_COUNT
    bne :-
    rts

; Animate a given sprite.  If it is not time to
; animate this frame, write the last frame again.
ls_SpriteAnimate:
    sta TmpX    ; A holds the obj sprite index

    ; ID -> DWORD index
    tay
    ldx data_Mult5, y

    ; sprite obj definition
    lda data_SpriteObject_List, x
    sta AddressPointer0+0
    inx
    lda data_SpriteObject_List, x
    sta AddressPointer0+1
    inx

    ; Base X/X
    lda data_SpriteObject_List, x
    sta tmp_BaseX
    inx
    lda data_SpriteObject_List, x
    sta tmp_BaseY
    inx

    ; Nametable
    lda #0
    sta tmp_SpriteFlags
    lda data_SpriteObject_List, x
    beq :+
    lda #$08
    sta tmp_SpriteFlags
:

    ; reload sprite obj ID
    ldx TmpX

    ; check if it's time to animate
    dec ls_SpriteFrameTimer, x
    bne @noAnim    ; not time to animate

    ; Update frame number
    inc ls_SpriteFrames, x
    lda ls_SpriteFrames, x

    ; frame count in the definition
    ldy #3
    cmp (AddressPointer0), y

    bcc :+
    ; handle overflow
    lda #0
    sta ls_SpriteFrames, x
:

    ; Reset the framerate counter
    ldy #1
    lda (AddressPointer0), y
    sta ls_SpriteFrameTimer, x

@noAnim:
    ; The animation data still needs to be written
    ; on every frame, the only difference is not
    ; updating the frame number.

    ; animation type
    ldy #0
    lda (AddressPointer0), y
    beq @ls_SpriteAnimate_Move
    iny
    ; static "animation"

    ; Sprite count
    lda (AddressPointer0), y
    sta IdxC
    iny

    ; Tile data pointer
    lda (AddressPointer0), y
    sta AddressPointer1+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer1+1
    iny

    ; Attribute data pointer
    lda (AddressPointer0), y
    sta AddressPointer2+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer2+1
    iny

    ; X data pointer
    lda (AddressPointer0), y
    sta AddressPointer3+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer3+1
    iny

    ; Y data pointer
    lda (AddressPointer0), y
    sta AddressPointer4+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer4+1
    iny

    ; individual sprites in obj
    lda #0
    sta IdxB    ; current sprite in obj
@spriteLoopA:
    ldy IdxB
    ldx menu_LoadedSprites

    lda (AddressPointer3), y
    clc
    adc tmp_BaseX
    sta ls_SpriteX, x

    lda (AddressPointer4), y
    clc
    adc tmp_BaseY
    sta ls_SpriteY, x

    lda (AddressPointer1), y
    sta ls_SpriteTiles, x

    lda (AddressPointer2), y
    sta ls_SpriteFlags, x

    jsr ls_SpriteScroll
    inx
    stx menu_LoadedSprites

    inc IdxB
    lda IdxB
    cmp IdxC
    bne @spriteLoopA
    rts

@ls_SpriteAnimate_Move:
    ldy #2
    lda (AddressPointer0), y
    sta IdxC    ; sprite count in obj

    ldy #4
    ; Tile data pointer
    lda (AddressPointer0), y
    sta AddressPointer1+0
    iny

    lda (AddressPointer0), y
    sta AddressPointer1+1
    iny

    ; Attribute data pointer
    lda (AddressPointer0), y
    sta AddressPointer2+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer2+1
    iny

    ; X data pointer
    lda (AddressPointer0), y
    sta AddressPointer3+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer3+1
    iny

    ; Y data pointer
    lda (AddressPointer0), y
    sta AddressPointer4+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer4+1
    iny

    ; Frame X data pointer
    lda (AddressPointer0), y
    sta AddressPointer5+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer5+1
    iny

    ; Frame Y data pointer
    lda (AddressPointer0), y
    sta AddressPointer6+0
    iny
    lda (AddressPointer0), y
    sta AddressPointer6+1
    iny

    ; Reload the current frame index
    lda ls_SpriteFrames, x
    tay

    ; Add base Y offset to frame X offset
    lda (AddressPointer5), y
    clc
    adc tmp_BaseX
    sta tmp_BaseX

    ; Add base Y offset to frame Y offset
    lda (AddressPointer6), y
    clc
    adc tmp_BaseY
    sta tmp_BaseY

    ; indiviual sprites in the obj
    lda #0
    sta IdxB    ; current sprite in obj
@spriteLoop:
    ; load sprite IDX in OBJ
    ldy IdxB

    ; foreach sprite in obj, write its X coord to RAM
    lda (AddressPointer3), y
    clc
    adc tmp_BaseX
    sta tmp_SpriteX

    ; foreach sprite in obj, write its Y coord to RAM
    lda (AddressPointer4), y
    clc
    adc tmp_BaseY
    sta tmp_SpriteY

    ; sprite tile
    lda (AddressPointer1), y
    sta tmp_SpriteTile

    ; sprite Attr
    lda (AddressPointer2), y
    ora tmp_SpriteFlags
    sta tmp_SpriteFlags

    ; copy values from tmp
    ldx menu_LoadedSprites

    lda tmp_SpriteX
    sta ls_SpriteX, x
    lda tmp_SpriteY
    sta ls_SpriteY, x

    lda tmp_SpriteTile
    sta ls_SpriteTiles, x
    lda tmp_SpriteFlags
    sta ls_SpriteFlags, x

    jsr ls_SpriteScroll
    inx
    stx menu_LoadedSprites

    ; increment current sprite in OBJ
    inc IdxB
    lda IdxB
    cmp IdxC    ; cmp to total sprites in OBJ
    bne @spriteLoop
    rts

LS_CURSOR_1 = Sprites + (4 * 1)
LS_CURSOR_2 = Sprites + (4 * 2)
LS_CURSOR_3 = Sprites + (4 * 3)
LS_CURSOR_4 = Sprites + (4 * 4)
LS_CURSOR_PAL = $03

; Load cursor values given the currently selected level.
ls_LoadCursor:
    ldx ls_SelectedLevel
    ldy ls_ActiveLevels, x
    ; Scroll screen
    lda data_LevelSelect_CursorScroll, y
    sta menu_ScrollValue

    ; index -> offset
    tya
    asl a
    asl a
    tay

    ;; Position and size
    ; Width/Height
    lda data_LevelSelect_Cursor + 2, y
    sta TmpX
    lda data_LevelSelect_Cursor + 3, y
    sta TmpY

    ; X/Y
    ldx data_LevelSelect_Cursor, y
    lda data_LevelSelect_Cursor + 1, y
    tay
    ; Fall into next routine

; Draw cursor at a given X/Y coordinate.
; X is in X regsiter
; Y is in Y register
; Width in TmpX
; Height in TmpY
ls_DrawCursorXY:
    ; X for left side
    stx LS_CURSOR_1 + 3
    stx LS_CURSOR_3 + 3

    ; Y for top
    sty LS_CURSOR_1 + 0
    sty LS_CURSOR_2 + 0

    ; X for right side
    txa
    clc
    adc TmpX
    sta LS_CURSOR_2 + 3
    sta LS_CURSOR_4 + 3

    ; Y for bottom
    tya
    clc
    adc TmpY
    sta LS_CURSOR_3 + 0
    sta LS_CURSOR_4 + 0

    ;; Tile
    lda #CURSOR_TILE
    sta LS_CURSOR_1 + 1
    sta LS_CURSOR_2 + 1
    sta LS_CURSOR_3 + 1
    sta LS_CURSOR_4 + 1

    ;; Attributes
    ; top left
    lda #LS_CURSOR_PAL
    sta LS_CURSOR_1 + 2

    ; top right
    lda #LS_CURSOR_PAL | $40
    sta LS_CURSOR_2 + 2

    ; bottom left
    lda #LS_CURSOR_PAL | $80
    sta LS_CURSOR_3 + 2

    ; bottom right
    lda #LS_CURSOR_PAL | $C0
    sta LS_CURSOR_4 + 2
    rts

TheStack = $0100
TheClear = $0130

ls_ResetTrace:
    lda menu_PrevLevel
    cmp #$0F
    bne :+
    rts
:
    asl a
    tax

    lda from_idx, x
    sta AddressPointer0
    lda from_idx+1, x
    sta AddressPointer0+1

    lda ls_SelectedLevel_Prev
    asl a
    tay

    lda (AddressPointer0), y
    sta AddressPointer1

    iny
    lda (AddressPointer0), y
    sta AddressPointer1+1

    ; load the data
    ldy #0
    ldx #0
    stx TmpZ    ; number of attr updates
@loop:
    lda (AddressPointer1), y
    sta TmpX    ; low byte
    iny
    lda (AddressPointer1), y
    beq @done   ; check high byte for NIL

    ; store the address
    sta TheClear, x

    lda TmpX    ; high stored first
    inx
    sta TheClear, x ;low byte second

    inc TmpZ
    iny
    iny
    inx
    jmp @loop
@done:

    lda TmpZ
    sta ls_AttrUpdate_Clr
    rts

; Light up the trace as determined by
; menu_PrevLevel and ls_SelectedLevel
ls_LightTrace:
    lda menu_PrevLevel
    cmp #$0F
    bne :+
    rts
:
    asl a
    tax

    lda from_idx, x
    sta AddressPointer0
    lda from_idx+1, x
    sta AddressPointer0+1

    lda ls_SelectedLevel
    asl a
    tay

    lda (AddressPointer0), y
    sta AddressPointer1
    sta ls_TmpTracePointer

    iny
    lda (AddressPointer0), y
    sta AddressPointer1+1
    sta ls_TmpTracePointer+1

ls_LightGivenTrace:
    ; load the data
    ldy #0
    ldx #0
    stx TmpZ    ; number of attr updates
@loop:
    lda (AddressPointer1), y
    sta TmpX    ; low byte
    iny
    lda (AddressPointer1), y
    beq @done   ; check high byte for NIL

    ; store the address
    sta TheStack, x
    sta AddressPointer2+1

    lda TmpX    ; high stored first
    inx
    sta TheStack, x ;low byte second
    sta AddressPointer2

    iny
    inx
    lda (AddressPointer1), y
    sta IdxC

    lda AddressPointer2
    cmp ls_PrevTraceAddr
    bne :+
    lda AddressPointer2+1
    cmp ls_PrevTraceAddr+1
    bne :+
    lda IdxC
    ora ls_PrevTraceData
    sta IdxC
:

    lda IdxC
    sta TheStack, x
    sta IdxD
    ;sta ls_PrevTraceData

    inc TmpZ
    iny
    inx
    jmp @loop
@done:

    lda TmpZ
    sta ls_AttrUpdate
    rts

ls_WriteTraceAttr:
    ; Backup stack pointer, and point it to $0100
    tsx
    stx IdxA    ; store stack pointer

    ; point stack to clear addresses
    ldx #$2F
    txs

    ldy ls_AttrUpdate_Clr
    beq @noClear
    ; Clear prev trace
    ldx #0
:
    pla
    sta $2006
    sta AddressPointer0+1
    pla
    sta $2006
    sta AddressPointer0

    lda AddressPointer0
    cmp ls_PrevTraceAddr
    bne :+
    lda AddressPointer0+1
    cmp ls_PrevTraceAddr+1
    bne :+
    lda ls_PrevTraceData
    sta $2007
    jmp :++
:
    stx $2007
:
    dey
    bne :---
    lda #0
    sta ls_AttrUpdate_Clr

@noClear:
    ; light new trace
    ldx #$FF
    txs
    ldy ls_AttrUpdate
    beq @noLight
:
    pla
    sta $2006
    pla
    sta $2006
    pla
    sta $2007
    dey
    bne :-

    lda #0
    sta ls_AttrUpdate

@noLight:
    ; Restore stack pointer
    ldx IdxA
    txs
    rts

ls_PrepLevelText:
    ;jsr TextClearStringBuffer
    ;jsr TextClearBuffer
    lda #1
    sta IgnoreInput

    ldx ls_SelectedLevel
    lda ls_ActiveLevels, x
    asl a
    tax

    lda ls_WriteText
    cmp #1
    beq @title
    cmp #2
    beq @line1
    cmp #3
    beq @line1
    ; line 2

    lda data_Level_Text_Line2_Idx+0, x
    sta AddressPointer0+0
    lda data_Level_Text_Line2_Idx+1, x
    sta AddressPointer0+1
    jmp @readText

@title:
    lda data_Level_Titles_Idx+0, x
    sta AddressPointer0+0
    lda data_Level_Titles_Idx+1, x
    sta AddressPointer0+1
    jmp @readText

@line1:
    lda data_Level_Text_Line1_Idx+0, x
    sta AddressPointer0+0
    lda data_Level_Text_Line1_Idx+1, x
    sta AddressPointer0+1

@readText:
    ldy #0
    ldx #0
:
    lda (AddressPointer0), y
    sta TextBuffer, x
    beq @doneRead
    inx
    iny
    jmp :-

@doneRead:
    ;jsr TextPrepare
    jmp TextPrepare_v3
    ;rts

; Write blank tiles to the text areas
ls_ClearText:
    bit $2002

    ; Title
    lda data_lsText_AddrTitle+1
    sta $2006
    lda data_lsText_AddrTitle+0
    sta $2006

    ldx #$FF
    .repeat 8
    stx $2007
    .endrepeat

    ; Line1
    lda data_lsText_AddrLine1+1
    sta $2006
    lda data_lsText_AddrLine1+0
    sta $2006

    ldx #$FF
    .repeat 15
    stx $2007
    .endrepeat

    ; Line2
    lda data_lsText_AddrLine2+1
    sta $2006
    lda data_lsText_AddrLine2+0
    sta $2006

    ldx #$FF
    .repeat 15
    stx $2007
    .endrepeat
    rts

; Start tile ID for the text
LS_TEXTTILE_OFFSET = $B0

; A = tile number to write
; X = tile count to write
ls_WriteTextTile:
    clc
    adc #LS_TEXTTILE_OFFSET
    tay

    rts

LSSPINNER_YSTART = 205
LSSPINNER_XSTART = 233
ls_AnimateSpinner:
    dec ls_SpinnerCount
    beq :+
    rts
:
    lda #SPINNER_DELAY
    sta ls_SpinnerCount
    ldx #$C0

    lda ls_SpinnerFlip
    eor #$FF
    sta ls_SpinnerFlip
    beq :+
    ; display non-mirrored
    lda #LSSPINNER_YSTART
    sta Sprites+(25*4)+0
    stx Sprites+(25*4)+1
    lda #$00
    sta Sprites+(25*4)+2
    lda #LSSPINNER_XSTART-1
    sta Sprites+(25*4)+3

    lda #LSSPINNER_YSTART+9
    sta Sprites+(26*4)+0
    stx Sprites+(26*4)+1
    lda #$C0
    sta Sprites+(26*4)+2
    lda #LSSPINNER_XSTART+8
    sta Sprites+(26*4)+3
    rts
:

    ; display mirrored
    lda #LSSPINNER_YSTART
    sta Sprites+(25*4)+0
    stx Sprites+(25*4)+1
    lda #$40
    sta Sprites+(25*4)+2
    lda #LSSPINNER_XSTART+8
    sta Sprites+(25*4)+3

    lda #LSSPINNER_YSTART+9
    sta Sprites+(26*4)+0
    stx Sprites+(26*4)+1
    lda #$80
    sta Sprites+(26*4)+2
    lda #LSSPINNER_XSTART-1
    sta Sprites+(26*4)+3
    rts

.include "level-select-data.asm"

; auto-generated from maps/lsbg-wang.tmx
.include "lsbg.i"

data_LS_Ui = :++
.include "lsbg_ui.i"
.byte $FF
