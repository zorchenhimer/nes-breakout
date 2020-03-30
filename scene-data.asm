; asmsyntax=ca65

; This should handle all cutscene stuff
; scene dirirection:
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

    .byte SceneCmd::DrawFullScene
        .byte 2 ; page 2
        .byte $20 ; dest nametable
        .byte ScreenIDs::News

    .byte SceneCmd::DrawFullScene
        .byte 2
        .byte $20
        .byte ScreenIDs::TextBox

    .byte SceneCmd::DrawText
        .word $22A9
        .asciiz "lel, welcome"

    .byte SceneCmd::DrawText
        .word $22C9
        .asciiz "to the news"

    .byte SceneCmd::TurnOnPPU

    .byte SceneCmd::WaitSeconds
        .byte 5

    .byte SceneCmd::GotoInit
        .byte InitIDs::Title
