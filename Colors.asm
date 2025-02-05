.const BLACK = $00
.const WHITE = $01
.const RED = $02
.const CYAN = $03
.const PURPLE = $04
.const GREEN = $05
.const BLUE = $06
.const YELLOW = $07
.const ORANGE = $08
.const BROWN = $09
.const PINK = $0a
.const DARK_GREY = $0b
.const GREY = $0c
.const LT_GREEN = $0d
.const LT_BLUE = $0e
.const LT_GRAY = $0f

//----------------------------------------------------------
// A little macro
.macro SetBorderColor(color) 
{
        lda #color
        sta $d020
}

.macro SetScreenColor(color) 
{
        lda #color
        sta $d021
}

.macro SetMultiColor1(color) 
{
        lda #color
        sta $d022
}

.macro SetMultiColor2(color) 
{
        lda #color
        sta $d023
}

.macro SetSprColor1(color) 
{
        lda #color
		sta $d025 // Spr color M0
}

.macro SetSprColor2(color) 
{
        lda #color
		sta $d026 // Spr color M1
}

