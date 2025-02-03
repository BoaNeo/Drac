_screenBits: .byte SCREEN1_BITS
_fontBits: .byte FONT_BITS
_scrollX: .byte 0
_screenPtr: .lohifill 25, 40*i

.macro SwapToBuffer1()
{
	SprSetScreenPt(_screen1,_screen2)

	lda #SCREEN1_BITS
	sta _screenBits
}

.macro SwapToBuffer2()
{
	SprSetScreenPt(_screen2,_screen1)

	lda #SCREEN2_BITS
	sta _screenBits
}

//------------------------------------------------------------
// ($fa)->: String
// $20->: Target Position X
// $21->: Target Position Y
// $fc->: Color


.macro DrawScreen(text)
{
	ClearScreen(_screen1, $a0)
	ClearScreen(_color1, $00)
	lda #<text
	sta $fa
	lda #>text
	sta $fb
	ldy #$ff
next:
	iny
	lda ($fa),y
	cmp #$ff
	beq exit
ok:	sta $fc
	iny
	lda ($fa),y
	sta $20
	iny
	lda ($fa),y
	sta $21
loop:
	iny
	sty $23
	lda ($fa),y
	beq next
	jsr DrawChar
	inc $20
	inc $20
	ldy $23
	jmp loop
exit:
	CopyScreen(_screen1, _screen2)
	CopyScreen(_color1, _color2)
	rts
}

.macro ClearScreen(screen, v)
{
	ldx #$00
	loop:
	lda #v
	sta screen,x
	sta screen+$100,x
	sta screen+$200,x
	inx
	bne loop
	ldx #231
	loop2:
	sta screen+$300,x
	dex
	bne loop2
	sta screen+$300,x
}

.macro CopyScreen(from, to)
{
	ldx #$00
	loop:
	lda from,x
	sta to,x
	lda from+$100,x
	sta to+$100,x
	lda from+$200,x
	sta to+$200,x
	inx
	bne loop
	ldx #231
	loop2:
	lda from+$300,x
	sta to+$300,x
	dex
	bne loop2
	lda from+$300,x
	sta to+$300,x
}


//------------------------------------------------------------
// $20->: Target Position X
// $21->: Target Position Y
// $fc->: Color
// A->: Char
DrawChar:
{
	sec
	sbc #$40
	tay
	lda _fontTilePtr,y
	sta $fe           	// Store the index as the low byte for the tilemap
	lda _fontTilePtr+$80,y
	sta $ff				// Now ($fe) points to the relevant tile

	// Set hi bytes
	ldy $21
	clc
	lda _screenPtr+25,y
	adc #(>_screen1)
	sta $29 // ($28) is now the screen buffer
	adc #$d8-(>_screen1)
	sta $27 // ($26) is now the color buffer

	// Set lo bytes
	ldy $21
	lda $20
	adc _screenPtr,y
	bcc !nohi+
	inc $27
	inc $29
	!nohi:
	sta $26
	sta $28

	ldx #2
	colloop:
		ldy #1
		rowloop:
			lda ($fe),y 	// Get the character from the tile
			sta ($28),y
			lda $fc
			sta ($26),y
			dey
			bpl rowloop

		Add_8to16($26,$27,40)
		Add_8to16($28,$29,40)
		inc $fe
		inc $fe
		dex
		bne colloop
	rts
}

