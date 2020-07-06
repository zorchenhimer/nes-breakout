; asmsyntax=ca65

; TODO: sprite-zero commands (moving it around?)
; TODO: extract static animation from test code
; TODO: New CHR for text box (ascii and text box BG)
; TODO: Palette data

; Scene ID in A, use the SceneIDs enum.
RunScene:
    asl a
    tax
    lda Scene_Index+0, x
    sta AddressPointer3+0
    lda Scene_Index+1, x
    sta AddressPointer3+1

    lda #0
    sta sf_AnimPointers+0
    sta sf_AnimPointers+1
    sta sf_AnimPointers+2
    sta sf_AnimPointers+3

    .NMI_Set NMI_Scene

@loop:
    ldy #0
    lda (AddressPointer3), y
    iny
    jsr scene_FunctionLaunch

    tya
    clc
    adc AddressPointer3
    sta AddressPointer3

    bcc :+
    inc AddressPointer3+1
:

    jmp @loop

@end:

    rts

scene_FunctionLaunch:
    asl a
    tax
    lda scene_Functions+1, x
    pha
    lda scene_Functions+0, x
    pha
    rts ; jump to function code

scene_Functions:
    .word sf_EOD-1
    .word sf_DrawFullScene-1
    .word sf_WaitSeconds-1
    .word sf_WaitFrames-1
    .word sf_SetSkippable-1
    .word sf_SetUnskippable-1
    .word sf_DrawText-1
    .word sf_TurnOffPPU-1
    .word sf_TurnOnPPU-1
    .word sf_FillNametable-1
    .word sf_LoadChr-1
    .word sf_PadSprites-1
    .word sf_SetPalette-1
    .word WriteTvAttr-1
    .word WriteStaticAttributes-1
    .word ClearAttrTable0-1
    .word ClearAttrTable1-1
    .word ClearAttrTable2-1
    .word ClearAttrTable3-1
    .word sf_SetFramePointer-1
    .word sf_SetNMIPointer-1
    .word sf_RunFunction-1
    .word sf_SetNametable0-1
    .word sf_SetNametable1-1
    .word sf_SetNametable2-1
    .word sf_SetNametable3-1
    .word sf_GotoInit-1

fn_lastidx = ((* - scene_Functions) / 2) - 1
.out .sprintf("fn_lastidx: %d", fn_lastidx)
.if fn_lastidx <> SceneCmd::GotoInit
    .error "scene_Functions table does not match SceneCmd enum!"
.endif

sf_EOD:
    brk ; u wot m8
    rts

sf_DrawFullScene:
    lda (AddressPointer3), y
    sta IdxA    ; source bank

    iny
    lda (AddressPointer3), y
    tax ; destination nametable

    ; increment and backup Y
    iny
    tya
    pha

    ; scene id
    lda (AddressPointer3), y
    pha

    lda $8000
    sta LastBank

    lda #2
    jsr MMC1_Select_Page

    pla ; get scene id from stac
    jsr LoadScreen

    lda LastBank
    jsr MMC1_Select_Page

    ; restore Y
    pla
    tay
    iny

    rts

scene_AnimLaunch:
    lda sf_AnimPointers+0, x
    sta AddressPointer0+0
    lda sf_AnimPointers+1, x
    sta AddressPointer0+1

    jmp (AddressPointer0)

; A = 0 Frame
; A = 1 NMI
scene_frameCode:
    asl a
    tax
    lda sf_AnimPointers+1, x
    beq :+
    lda $8000
    sta LastBank

    lda sf_AnimBank
    jsr MMC1_Select_Page

    tya
    pha

    jsr scene_AnimLaunch

    pla
    tay

    lda LastBank
    jsr MMC1_Select_Page
:
    rts

sf_WaitSeconds:
    ; turn on PPU here?
    lda (AddressPointer3), y
    iny
    sta sf_Seconds

@seconds:
    .ifdef PAL
    lda #50
    .else
    lda #60
    .endif
    sta sf_Frames

@frames:
    ; frame code
    lda #0
    jsr scene_frameCode

    jsr WaitForNMI
    dec sf_Frames
    bne @frames

    dec sf_Seconds
    bne @seconds

    rts

sf_WaitFrames:
    ; turn on PPU here?
    lda (AddressPointer3), y
    iny
    sta sf_Frames

    .NMI_Set NMI_Scene

:
    ; frame code
    lda #0
    jsr scene_frameCode

    jsr WaitForNMI
    dec sf_Frames
    bne :-
    rts

sf_SetSkippable:
    lda #1
    sta sf_Skippable
    rts

sf_SetUnskippable:
    lda #0
    sta sf_Skippable
    rts

sf_DrawText:
    bit $2002
    lda (AddressPointer3), y
    pha
    iny
    lda (AddressPointer3), y
    sta $2006
    pla
    sta $2006

@text:
    iny
    lda (AddressPointer3), y
    beq @done
    sta $2007
    jmp @text
@done:

    rts

sf_TurnOffPPU:
    .Disable_Drawing
    rts

sf_TurnOnPPU:
    lda #1
    sta sf_PpuOn
    jsr WaitForNMI
    rts

sf_FillNametable:
    brk
    rts

sf_LoadChr:
    lda $8000
    sta LastBank

    lda #0
    sta AddressPointer5

    ; Dest pattern table
    ;iny
    lda (AddressPointer3), y
    and #$80

    beq :+
    lda #$10
:
    ; AddressPointer0 is the dest start address for CHR
    sta AddressPointer5+1

    ; Source Page
    lda (AddressPointer3), y
    and #$7F
    jsr MMC1_Select_Page

    ; Dest offset (in tiles)
    iny
    lda (AddressPointer3), y

    ; tiles -> address
    tax
    lda data_Mult16_A, x
    sta AddressPointer5+0

    lda AddressPointer5+1
    ora data_Mult16_B, x
    sta AddressPointer5+1

    ; Tile count
    iny
    lda (AddressPointer3), y
    sta ChrWriteTileCount

    iny
    lda (AddressPointer3), y
    sta AddressPointer4

    iny
    lda (AddressPointer3), y
    sta AddressPointer4+1
    iny

    ; Save Y
    tya
    pha

    jsr WriteChrData

    ; Restore Y
    pla
    tay

    lda LastBank
    jmp MMC1_Select_Page

sf_PadSprites:
    ldx LastSpriteOffset
    lda #$FE
:
    sta Sprites, x
    inx
    inx
    inx
    inx
    bne :-

    rts

sf_SetPalette:
    lda (AddressPointer3), y
    asl a
    asl a
    tax
    clc
    adc #4
    sta TmpX ; exit condition
    iny

@loop:
    lda (AddressPointer3), y
    sta PaletteBuffer, x
    iny
    inx
    cpx TmpX
    bne @loop

    rts

sf_SetFramePointer:
    lda (AddressPointer3), y
    sta sf_AnimPointers+0
    iny

    lda (AddressPointer3), y
    sta sf_AnimPointers+1
    iny
    rts

sf_SetNMIPointer:
    lda (AddressPointer3), y
    sta sf_AnimPointers+2
    iny

    lda (AddressPointer3), y
    sta sf_AnimPointers+3
    iny
    rts

sf_RunFunction:
    lda (AddressPointer3), y
    sta AddressPointer0+0
    iny

    lda (AddressPointer3), y
    sta AddressPointer0+1
    iny

    jmp (AddressPointer0)

sf_SetNametable0:
    lda #$00
    sta sf_Nametable
    rts

sf_SetNametable1:
    lda #$01
    sta sf_Nametable
    rts

sf_SetNametable2:
    lda #$02
    sta sf_Nametable
    rts

sf_SetNametable3:
    lda #$03
    sta sf_Nametable
    rts

sf_GotoInit:
    lda (AddressPointer3), y
    jmp JumpToInit

NMI_Scene:
    pha
    lda sf_PpuOn
    beq :+
    ;lda #0
    ;sta sf_PpuOn

    jsr WriteSprites
    jsr WritePalettes

    lda #1
    jsr scene_frameCode

    ; TODO: put the values into variables
    .Update_PpuMask PPU_MASK_ON | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND

    lda #PPU_CTRL_NMI | PPU_CTRL_SP_PATTERN
    ora sf_Nametable
    sta $2000

    lda #0
    sta $2005
    sta $2005
:
    dec Sleeping
    pla
    rti
