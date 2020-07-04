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

    .byte SceneCmd::PadSprites

    .byte SceneCmd::TurnOnPPU

    .byte SceneCmd::WaitSeconds
        .byte 5

    .byte SceneCmd::TurnOffPPU
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

    ;.byte SceneCmd::DrawText
    ;    .word $22A9
    ;    .asciiz "lel, welcome"

    ;.byte SceneCmd::DrawText
    ;    .word $22C9
    ;    .asciiz "to the news"

    .byte SceneCmd::TurnOnPPU

    .byte SceneCmd::WaitSeconds
        .byte 5

    .byte SceneCmd::GotoInit
        .byte InitIDs::Title
