; asmsyntax=ca65

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
