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

// Color order dark to light: BLACK, BLUE, BROWN, RED, DARK_GRAY, PURPLE, ORANGE, LIGHT_BLUE, GRAY, GREEN, LIGHT_RED, CYAN, LIGHT_GRAY, YELLOW, LIGHT_GREEN, WHITE
_fadeToBlack:
.byte BLACK, LIGHT_GREEN, BROWN, LIGHT_RED, DARK_GRAY, GRAY, BLACK, LIGHT_GRAY, PURPLE, BLUE, GREEN, RED, LIGHT_BLUE, YELLOW, ORANGE, CYAN
_fadeToWhite:
.byte BLUE, WHITE, DARK_GRAY, LIGHT_GRAY, ORANGE, LIGHT_RED, BROWN, LIGHT_GREEN, LIGHT_BLUE, RED, CYAN, PURPLE, GREEN, WHITE, GRAY, YELLOW
_fadeToBlackMultiColor:
.byte BLACK, YELLOW, BLUE, GREEN, RED, PURPLE, BLACK, CYAN, BLACK+8, YELLOW+8, BLUE+8, GREEN+8, RED+8, PURPLE+8, BLACK+8, CYAN+8 

// Color order dark to light: BLACK, BLUE, BROWN, RED, DARK_GRAY, PURPLE, ORANGE, LIGHT_BLUE, GRAY, GREEN, LIGHT_RED, CYAN, LIGHT_GRAY, YELLOW, LIGHT_GREEN, WHITE



FadeToBlack:
{
        FADE_TO_BLACK($d020)
        FADE_TO_BLACK($d021)
        FADE_TO_BLACK($d022)
        FADE_TO_BLACK($d023)
        FADE_TO_BLACK($d025)
        FADE_TO_BLACK($d026)

        ldy #$00
        loop:
        lda $d800,y
        and #$0f
        tax
        lda _fadeToBlack,x
        sta $d800,y
        lda $d900,y
        and #$0f
        tax
        lda _fadeToBlack,x
        sta $d900,y
        lda $da00,y
        and #$0f
        tax
        lda _fadeToBlack,x
        sta $da00,y
        iny
        bne loop
        ldy #0
        loop2:
        lda $db00,y
        and #$0f
        tax
        lda _fadeToBlack,x
        sta $db00,y
        iny
        cpy #232
        bne loop2

        rts

}

.macro FADE_TO_BLACK(reg)
{
        lda reg
        and #$0f
        tax
        lda _fadeToBlack,x
        sta reg
}


