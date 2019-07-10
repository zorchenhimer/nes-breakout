; asmsyntax=ca65

; Map Metadata

NUMBER_OF_MAPS = 1

Index_Maps:
    .word Meta_Map00
    .word Meta_Map01

Meta_Map00:
    .word Data_Map00_Tiles  ; Tile data
    .word $0000 ;Data_Map00_Spawn  ; Child board spawn IDs
    .word $0000 ;Data_Map00_Powerup    ; Powerup IDs
    .word $0000 ;Data_Map00_Powerdown  ; Powerdown IDs
    .byte $00

; %0        No brick
; %10       Standard brick (health)
; %110      Child spawn
; %1110     Powerup
; %11110    PowerDown
Data_Map00_Tiles:
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010
    .byte %10101010, %10101010, %10101010

Meta_Map01:
    .word Data_Map01_Tiles
    .word Data_Map01_Spawn
    .word Data_Map01_Powerup
    .word Data_Map01_Powerdown
    .byte $01

Data_Map01_Tiles:
    .byte %11000000, %11000000, %00000000, %00001110    ; first row, first brick of second row
    .byte %00001110, %00000000, %00000000, %00011110    ; second row, and first brick of third
    .byte %11110000, %00000000, %00000000, %00000000    ; third row, and first four bricks of fourth
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00000000
    .byte %00000000, %00000000, %00010000

Data_Map01_Spawn:
    .byte $00, $01, $02

Data_Map01_Powerup:
    .byte $03, $04, $05

Data_Map01_Powerdown:
    .byte $06, $07, $08
