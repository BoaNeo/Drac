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

