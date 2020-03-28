; asmsyntax=ca65

; This should handle all cutscene stuff
; scene dirirection:
;   - draw a scene on the background
;   - update CHR
;   - add/remove sprites
;   - set timer for scene changes
; this will all be encoded in some sort of binary format

Scene_Intro:
    .byte SceneCmd::SetSkippable

    .byte SceneCmd::DrawFullScene
        .byte 2 ; page 2
        .word screen_News

    .byte SceneCmd::DrawText
        .word $22CA
        .byte "lel, welcome to"

    .byte SceneCmd::DrawText
        .word $22EA
        .byte "the news"

    .byte SceneCmd::WaitSeconds
        .byte 5

    .byte SceneCmd::GotoInit
        .byte 0  ; title
    .byte $00 ; last resort end
