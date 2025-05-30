_screenBits: .byte SCREEN1_BITS
_fontBits: .byte FONT_BITS
_scrollX: .byte 0
_screen1RowOffset: .lohifill 25, _screen1+40*i
_colorRowOffset: .lohifill 25, $d800+40*i

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
// $fc  ->: Default Color (if bit 7 is set, this color overrides the one from the text)

ClearScreen1:
{
	ClearScreen(_screen1, $a0)
	rts
}
ClearScreen2:
{
	ClearScreen(_screen2, $a0)
	rts
}
ClearColor1:
{
	ClearScreen(_color1, $00)
	rts
}
ClearColor2:
{
	ClearScreen(_color2, $00)
	rts
}
ClearColorRam:
{
	ClearScreen($d800,0)
	rts
}
ApplyColorBuffer1:
{
	CopyScreen(_color1, $d800)
	rts
}
ApplyColorBuffer2:
{
	CopyScreen(_color2, $d800)
	rts
}


DrawScreen:
{
	next_line:
		ldy #$00
		lda ($fa),y
		cmp #$ff
		beq exit
		sta $fc
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
		bne next_char
			iny
			tya
			clc
			adc $fa
			sta $fa
			bcc next_line
			inc $fb
			jmp next_line
	next_char:
		jsr DrawChar
		ldy $23
		jmp loop
	exit:
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
		cmp #$40
		bcs large_font

		sta $fe

		// Set hi bytes
		ldy $21
		iny
		lda _screen1RowOffset.hi,y
		sta $29 
		clc
		adc #(>_color1)-(>_screen1)
		sta $27 
		// Set lo bytes
		lda _screen1RowOffset.lo,y
		sta $26 // ($26) is now the color buffer
		sta $28 // ($28) is now the screen buffer

		ldy $20
		lda $fe
		sta ($28),y
		lda $fc
		sta ($26),y
		inc $20
		rts

	large_font:
		sbc #$40
		tax
		lda _fontTilePtr.lo,x
		sta $fe           	// Store the index as the low byte for the tilemap
		lda _fontTilePtr.hi,x
		sta $ff				// Now ($fe) points to the relevant tile

		// Set hi bytes
		ldy $21
		lda _screen1RowOffset.hi,y
		sta $29
		clc
		adc #(>_color1)-(>_screen1)
		sta $27

		// Set lo bytes
		lda $20
		clc
		adc _screen1RowOffset.lo,y
		bcc !nohi+
		inc $27
		inc $29
	!nohi:
		sta $26 // ($26) is now the color buffer
		sta $28 // ($28) is now the screen buffer

		ldy #$00
		lda ($fe),y 	// Get the character from the tile
		sta ($28),y
		lda $fc
		sta ($26),y
		iny
		sta ($26),y
		lda ($fe),y 	// Get the character from the tile
		sta ($28),y

		iny
		lda ($fe),y 	// Get the character from the tile
		tax
		iny
		lda ($fe),y 	// Get the character from the tile

		ldy #41
		sta ($28),y
		lda $fc
		sta ($26),y
		dey
		sta ($26),y

		txa
		sta ($28),y

		inc $20
		inc $20
		rts
}

//------------------------------------------------------------
// $20->: Target Position X
// $21->: Target Position Y
// A->: Tile

DrawTile:
{
		tax
		lda _fontTilePtr.lo,x
		sta $fe           	// Store the index as the low byte for the tilemap
		lda _fontTilePtr.hi,x
		sta $ff				// Now ($fe) points to the relevant tile

		// Set hi bytes
		ldy $21
		lda _screen1RowOffset.hi,y
		sta $29

		// Set lo bytes
		lda $20
		clc
		adc _screen1RowOffset.lo,y
		bcc !nohi+
		inc $29
	!nohi:
		sta $28 // ($28) is now the screen buffer

		ldy #$00
		lda ($fe),y 	// Get the character from the tile
		sta ($28),y
		iny
		lda ($fe),y 	// Get the character from the tile
		sta ($28),y

		iny
		lda ($fe),y 	// Get the character from the tile
		tax
		iny
		lda ($fe),y 	// Get the character from the tile
		ldy #41
		sta ($28),y
		dey
		txa
		sta ($28),y

		rts
}
