; asmsyntax=ca65

; This should handle all cutscene stuff
; scene dirirection (spleling counts):
;   - draw a scene on the background
;   - update CHR
;   - add/remove sprites
;   - set timer for scene changes
; this will all be encoded in some sort of binary format



Scene_Index:
    .word Scene_Intro

Scene_Intro:
    .byte SceneCmd::SetSkippable

    .byte SceneCmd::SetExitRoutine
        .byte InitIDs::Title

    .byte SceneCmd::TurnOffPPU

    .byte SceneCmd::LoadChr
        .byte $00 | 14 ; dest pattern table (bit 7) & page
        .byte 0 ; Dest tile offset
        .byte TvTileData_Count; tile count
        .word TvTileData ; Source label

    .byte SceneCmd::LoadChr
        .byte $80 | 14 ; dest pattern table (bit 7) & page
        .byte 0 ; Dest tile offset
        .byte TvTileDataLower_Count; tile count
        .word TvTileDataLower ; Source label

    .byte SceneCmd::DrawFullScene
        .byte 2 ; page 2
        .byte $20 ; dest nametable
        ;
        ; This should be the news scene
        .byte ScreenIDs::News

    .byte SceneCmd::DrawFullScene
        .byte 2 ; page 2
        .byte $24 ; dest nametable
        ;
        ; This should be the news scene
        .byte ScreenIDs::TvStatic

    .byte SceneCmd::DrawFullScene
        .byte 2
        .byte $20
        .byte ScreenIDs::TextBox

    .byte SceneCmd::DrawFullScene
        .byte 2
        .byte $24
        .byte ScreenIDs::TextBox

    .byte SceneCmd::PadSprites

    .byte SceneCmd::SetPalette
        ; dest palette.
        ; 0-3: BG
        ; 4-7: Sprites
        .byte 0
        ; 4 bytes for the colors
        ;.byte $0F, $2A, $20, $3A
        .byte $0F, $10, $00, $0F

    .byte SceneCmd::SetPalette
        ; dest palette.
        ; 0-3: BG
        ; 4-7: Sprites
        .byte 1
        ; 4 bytes for the colors
        ;.byte $0F, $00, $20, $10
        .byte $0F, $17, $37, $17

    .byte SceneCmd::SetPalette
        .byte 2
        .byte $0F, $30, $37, $10

    .byte SceneCmd::SetPalette
        .byte 3
        .byte $0F, $0F, $10, $30

    .byte SceneCmd::SetPalette
        ; dest palette.
        ; 0-3: BG
        ; 4-7: Sprites
        .byte 4
        ; 4 bytes for the colors
        .byte $0F, $10, $00, $0F
        ;.byte $0F, $0F, $0F, $0F

    .byte SceneCmd::ClearAttr0
    .byte SceneCmd::ClearAttr1

    ;.byte SceneCmd::TvAttr
    .byte SceneCmd::RunFunction
        .word WriteNewsAttr
    ;.byte SceneCmd::StaticAttr
    .byte SceneCmd::RunFunction
        .word WriteStaticAttributes

    .byte SceneCmd::PrepareText
        .word $22A8 ; NT address
        ;.word $0820 ; CHR address
        .byte 0     ; ID
        .byte $90 ; start tile ID
        ;.byte 16    ; Length

    .byte SceneCmd::PrepareText
        .word $22C8 ; NT address
        ;.word $0920 ; CHR address
        .byte 1     ; ID
        .byte $A0 ; start tile ID
        ;.byte 16    ; length

    .byte SceneCmd::DrawText
        ;.word $22A9
        .byte 0 | $80 ; text area id
        .asciiz "lel, welcome to the"

    .byte SceneCmd::DrawText
        .byte 1 | $80 ; text area id
        ;.word $22C9
        .asciiz "news"

    .byte SceneCmd::RunFunction
        .word InitStatic

    .byte SceneCmd::TurnOnPPU

    .byte SceneCmd::WaitSeconds
        .byte 10

    .byte SceneCmd::SetFramePointer
        .word Frame_ScreenTest

    .byte SceneCmd::SetNMIPointer
        .word NMI_ScreenTest

    .byte SceneCmd::WaitSeconds
        .byte 3

    .byte SceneCmd::SetNametable1

    ; clear the frame pointer.  no more static lines
    .byte SceneCmd::SetFramePointer
        .word $0000

    .byte SceneCmd::WaitSeconds
        .byte 2

    .byte SceneCmd::TurnOffPPU
    .byte SceneCmd::SetNametable0

    .byte SceneCmd::DrawFullScene
        .byte 2 ; page 2
        .byte $20 ; dest nametable
        ;
        ; This should be the news scene
        .byte ScreenIDs::Hood

    ; Draw Full Scene, text box
    .byte SceneCmd::DrawFullScene
        .byte 2
        .byte $20
        .byte ScreenIDs::TextBox

    .byte SceneCmd::SetPalette
        .byte 1
        .byte $0F, $00, $20, $10

    .byte SceneCmd::SetPalette
        .byte 2
        .byte $0F, $00, $20, $10

    .byte SceneCmd::SetFramePointer
        .word Frame_ScreenTest

    .byte SceneCmd::TurnOnPPU

    .byte SceneCmd::WaitSeconds
        .byte 2

    .byte SceneCmd::SetFramePointer
        .word $0000

    .byte SceneCmd::WaitSeconds
        .byte 10

    .byte SceneCmd::GotoInit
