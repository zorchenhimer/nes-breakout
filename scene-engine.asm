; asmsyntax=ca65

; TODO: sprite-zero commands (moving it around?)
; TODO: extract static animation from test code
; TODO: New CHR for text box (ascii and text box BG)

; Scene ID in A, use the SceneIDs enum.
RunScene:
    asl a
    tax
    lda Scene_Index+0, x
    sta AddressPointer3+0
    lda Scene_Index+1, x
    sta AddressPointer3+1

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
    .word sf_GotoInit-1

sf_EOD:
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

    jsr LoadScreen

    ; restore Y
    pla
    tay
    iny

    jsr ClearAttrTable0

    rts

sf_WaitSeconds:
    ; turn on PPU here?
    lda (AddressPointer3), y
    sta sf_Seconds

@seconds:
    .ifdef PAL
    lda #50
    .else
    lda #60
    .endif
    sta sf_Frames

@frames:
    ; TODO: frame code?

    jsr WaitForNMI
    dec sf_Frames
    bne @frames

    dec sf_Seconds
    bne @seconds

    rts

sf_WaitFrames:
    ; turn on PPU here?
    lda (AddressPointer3), y
    sta sf_Frames

    .NMI_Set NMI_Scene

:
    ; TODO: frame code?

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

sf_GotoInit:
    lda (AddressPointer3), y
    jmp JumpToInit

NMI_Scene:
    lda sf_PpuOn
    beq :+
    lda #0
    sta sf_PpuOn
    ; TODO: put the values into variables
    .Update_PpuMask PPU_MASK_ON | PPU_MASK_LEFTSPRITES | PPU_MASK_LEFTBACKGROUND
    .Update_PpuControl PPU_CTRL_NMI | PPU_CTRL_SP_PATTERN
    lda #0
    sta $2005
    sta $2005
:
    dec Sleeping
    rti
