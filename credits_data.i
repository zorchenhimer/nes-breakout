credits_data_chunks:
; Blank row before special thanks
cr_data_chunk_00:
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00

; Top half of header
cr_data_chunk_01:
    .byte CR_OP_RLE, 7, $20
    .byte CR_OP_INC_BYTE, 3, $10
    .byte CR_OP_INC_BYTE, 7, $02
    .byte CR_OP_RLE, 22, $20
    .byte CR_OP_INC_BYTE, 3, $13
    .byte CR_OP_INC_BYTE, 15, $80
    .byte CR_OP_RLE, 7, $20
    .byte CR_OP_ATTR, $00

; Bottom half of header
cr_data_chunk_02:
    .byte CR_OP_RLE, 7, $20
    .byte CR_OP_INC_BYTE, 3, $16
    .byte CR_OP_INC_BYTE, 15, $90
    .byte CR_OP_RLE, 7, $20
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00

; Blank row before Miha's credit
cr_data_chunk_03:
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00

; Special thanks for MihaBrumecArt
cr_data_chunk_04:
    .byte CR_OP_RLE, 8, $20
    .byte CR_OP_INC_BYTE, 16, $A0
    .byte CR_OP_RLE, 16, $20
    .byte CR_OP_INC_BYTE, 16, $B0
    .byte CR_OP_RLE, 8, $20
    .byte CR_OP_ATTR, $0F

; Special thanks for MihaBrumecArt
cr_data_chunk_05:
    .byte CR_OP_RLE, 8, $20
    .byte CR_OP_INC_BYTE, 16, $C0
    .byte CR_OP_RLE, 16, $20
    .byte CR_OP_INC_BYTE, 16, $D0
    .byte CR_OP_RLE, 8, $20
    .byte CR_OP_ATTR, $0F

; Blank row before music credit
cr_data_chunk_06:
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00

; Special thanks for music
cr_data_chunk_07:
    .byte CR_OP_RLE, 13, $20
    .byte CR_OP_INC_BYTE, 7, $09
    .byte CR_OP_RLE, 21, $20
    .byte CR_OP_INC_BYTE, 14, $E1
    .byte CR_OP_RLE, 9, $20
    .byte CR_OP_ATTR, $F0

; Special thanks for music, pt2
cr_data_chunk_08:
    .byte CR_OP_RLE, 9, $20
    .byte CR_OP_INC_BYTE, 14, $F1
    .byte CR_OP_RLE, 9, $20
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $F0

; Blank row before names
cr_data_chunk_09:
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00

cr_data_chunk_10: .byte CR_OP_NAME, $0F, "01 Connie Klein"
cr_data_chunk_11: .byte CR_OP_NAME, $12, "02 Stephanie Blake"
cr_data_chunk_12: .byte CR_OP_NAME, $10, "03 Rosie Burgess"
cr_data_chunk_13: .byte CR_OP_NAME, $0D, "04 Ida Harmon"
cr_data_chunk_14: .byte CR_OP_NAME, $10, "05 Emmett Murray"
cr_data_chunk_15: .byte CR_OP_NAME, $0C, "06 Paul Lowe"
cr_data_chunk_16: .byte CR_OP_NAME, $14, "07 Christina Clayton"
cr_data_chunk_17: .byte CR_OP_NAME, $10, "08 Lucille Scott"
cr_data_chunk_18: .byte CR_OP_NAME, $15, "09 Jennifer Carpenter"
cr_data_chunk_19: .byte CR_OP_NAME, $0D, "10 Doyle Ryan"
cr_data_chunk_20: .byte CR_OP_NAME, $10, "11 Ricky Robbins"
cr_data_chunk_21: .byte CR_OP_NAME, $10, "12 Tyler Hammond"
cr_data_chunk_22: .byte CR_OP_NAME, $0E, "13 Rene Palmer"
cr_data_chunk_23: .byte CR_OP_NAME, $10, "14 Damon Hopkins"
cr_data_chunk_24: .byte CR_OP_NAME, $50, "15 Sandra Willis"
cr_data_chunk_25: .byte CR_OP_NAME, $0F, "16 Pete Russell"
cr_data_chunk_26: .byte CR_OP_NAME, $0E, "17 Dean Waters"
cr_data_chunk_27: .byte CR_OP_NAME, $0C, "18 Anne Cook"
cr_data_chunk_28: .byte CR_OP_NAME, $0F, "19 Seth Coleman"
cr_data_chunk_29: .byte CR_OP_NAME, $0F, "20 Ellis Walton"
cr_data_chunk_30: .byte CR_OP_NAME, $8F, "21 Doris Cooper"
cr_data_chunk_31: .byte CR_OP_NAME, $0F, "22 Vicky Parker"
cr_data_chunk_32: .byte CR_OP_NAME, $13, "23 Ernestine Larson"
cr_data_chunk_33: .byte CR_OP_NAME, $11, "24 Edna Jefferson"
cr_data_chunk_34: .byte CR_OP_NAME, $0E, "25 Judy Garner"
cr_data_chunk_35: .byte CR_OP_NAME, $8E, "26 Leon Barker"
cr_data_chunk_36: .byte CR_OP_NAME, $50, "27 Claire Rogers"
cr_data_chunk_37: .byte CR_OP_NAME, $95, "28 Priscilla Caldwell"
cr_data_chunk_38: .byte CR_OP_NAME, $14, "29 Lillian Carpenter"
cr_data_chunk_39: .byte CR_OP_NAME, $10, "30 Justin Graves"
cr_data_chunk_40: .byte CR_OP_NAME, $11, "31 Katrina Walton"
cr_data_chunk_41: .byte CR_OP_NAME, $0C, "32 Cody Ross"
cr_data_chunk_42: .byte CR_OP_NAME, $0F, "33 Nettie Curry"
cr_data_chunk_43: .byte CR_OP_NAME, $0E, "34 Benny Lewis"
cr_data_chunk_44: .byte CR_OP_NAME, $13, "35 Lindsey Sullivan"
cr_data_chunk_45: .byte CR_OP_NAME, $0F, "36 Lionel Banks"
cr_data_chunk_46: .byte CR_OP_NAME, $0E, "37 Katie Casey"
cr_data_chunk_47: .byte CR_OP_NAME, $0D, "38 Erika Cook"
cr_data_chunk_48: .byte CR_OP_NAME, $0E, "39 Wanda Klein"
cr_data_chunk_49: .byte CR_OP_NAME, $0D, "40 Dewey Rice"
cr_data_chunk_50: .byte CR_OP_NAME, $14, "41 Jermaine Harrison"
cr_data_chunk_51: .byte CR_OP_NAME, $0F, "42 Mandy Jensen"
cr_data_chunk_52: .byte CR_OP_NAME, $0F, "43 Abraham West"
cr_data_chunk_53: .byte CR_OP_NAME, $13, "44 Perry Williamson"
cr_data_chunk_54: .byte CR_OP_NAME, $12, "45 Lindsay Francis"
; Bottom padding for Attribute
cr_data_chunk_55:
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00

cr_data_chunk_56: .byte CR_OP_NAME, $0B, "Thank you!!"
; Bottom padding for Attribute
cr_data_chunk_57:
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00

; Bottom padding for Attribute
cr_data_chunk_58:
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_CLEAR_ROW
    .byte CR_OP_ATTR, $00
    .byte CR_OP_EOD

