
_drawers: .word DrawMap0-1, DrawMap1-1, DrawMap2-1, DrawMap3-1, DrawMap4-1, DrawMap5-1, DrawMap6-1, DrawMap7-1
_mapScrollEnabled: .byte 0
_mapScrollLooped: .byte 0
_drawMapPass: .byte 0
_tileOffset: .byte 0
_tileIndex: .byte 0
_mapWidth: .byte 0

//------------------------------------------------------------
// ($fc) -> Map address
// $fb -> Map Width
InitMap:
{
	lda $fb
	sta _mapWidth
	lda #<_mapEnd
	sta $fe
	lda #>_mapEnd
	sta $ff

	INIT_ROW(_activeMapRow0)
	INIT_ROW(_activeMapRow1)
	INIT_ROW(_activeMapRow2)
	INIT_ROW(_activeMapRow3)
	INIT_ROW(_activeMapRow4)

	lda #0
	sta _tileIndex
	lda #1
	sta _mapScrollEnabled
	sta _mapScrollLooped
	rts
}

DrawMap:
{
	lda _mapScrollEnabled
	beq noscroll

	ldx _drawMapPass
    lda _drawers+1,x
    pha
    lda _drawers,x
    pha
    inx
    inx
    cpx #16
    bne exit
    ldx #0
	exit:
	    stx _drawMapPass
    noscroll:
    rts
}

DrawMap0:
	ScrollX(6,GFX0_BITS)
	SwapToBuffer1()
	CopyColors(_color1)
	rts

DrawMap1:
	ScrollX(4,GFX2_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 0, 7)
	rts

DrawMap2:
	ScrollX(2,GFX4_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 7, 7)
	rts

DrawMap3:
	ScrollX(0,GFX6_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 14, 6)
	FillEdge(_activeMapRow0, 0, _screen2, _color2)
	FillEdge(_activeMapRow1, 4, _screen2, _color2)
	FillEdge(_activeMapRow2, 8, _screen2, _color2)
	FillEdge(_activeMapRow3, 12, _screen2, _color2)
	FillEdge(_activeMapRow4, 16, _screen2, _color2)
	jsr TokenScan
	jmp NextColumn

DrawMap4:
	ScrollX(6,GFX0_BITS)
	SwapToBuffer2()
	CopyColors(_color2)
	rts

DrawMap5:
	ScrollX(4,GFX2_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 0, 7)
	rts

DrawMap6:
	ScrollX(2,GFX4_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 7, 7)
	rts

DrawMap7:
	ScrollX(0,GFX6_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 14, 6)
	FillEdge(_activeMapRow0, 0, _screen1, _color1)
	FillEdge(_activeMapRow1, 4, _screen1, _color1)
	FillEdge(_activeMapRow2, 8, _screen1, _color1)
	FillEdge(_activeMapRow3, 12, _screen1, _color1)
	FillEdge(_activeMapRow4, 16, _screen1, _color1)
	jsr TokenScan
	jmp NextColumn

.macro INIT_ROW(row)
{
	ldy $fb
	dey
	!copy:
		lda ($fc),y
		sta row,y
		dey
		bpl !copy-
	ldx $fb
	ldy #0
	!copy:
		lda ($fe),y
		sta row,x
		inx
		iny
		cpy _mapEndWidth
		bne !copy-
	lda $fe
	clc
	adc _mapEndWidth
	sta $fe
	lda $fc
	clc
	adc $fb
	sta $fc	
	bcc nohi
		inc $fd
	nohi:
}

.macro ScrollX(amount, font_bits)
{
	lda #%11010000 // Turn on multicolor mode and shrink screen to 38 columns
	ora #amount
	sta _scrollX
//	sta $d016
	lda #font_bits
	sta _fontBits
}

.macro ShiftBuffers(char_src, char_dest, color_src, color_dest, row0, row_count)
{
	ldx #38
	loop:
	.for(var row=row0;row<row0+row_count;row++)
	{
		ldy color_src + row*40+1,x
		lda char_src + row*40+1,x
		bpl store
		ldy _backgroundColors + row*40+1,x
		lda _background + row*40+1,x
		store:
		sta char_dest+row*40,x
		tya
		sta color_dest+row*40,x
	}
	dex
	bmi exit
	jmp loop
	exit:
}

.macro FillEdge(map_row, row0, screen, color)
{
	ldx _tileIndex		// Get the next tile index
	lda map_row,x
	tax
	lda _tilePtr.lo,x
	sta $fe           	// Store the index as the low byte for the tilemap
	sta $fc
	lda _tilePtr.hi,x
	sta $ff				// Now ($fe) points to the relevant tile
	clc
	adc #(>_tileColors)-(>_tiles)	// Add the highbyte of the tile map to the color tile offset
	sta $fd 			// Now ($fc) points to the relevant color tile

	ldy _tileOffset   	// Tiles are arranged row-first, so index by y and increase one for each row
	.for(var row=0;row<4;row++)
	{
		lda ($fc),y
		tax
		lda ($fe),y 	// Get the character from the tile
		bpl store 		// negative values are background, so copy from the background
		ldx _backgroundColors+39+(row0+row)*40
		lda _background+39+(row0+row)*40
		store: 			// Store character at edge
		stx color+39+(row0+row)*40
		sta screen+39+(row0+row)*40
		iny
	}
}

.macro CopyColors(colors)
{
	ldx #$00
	loop:
	lda colors,x
	sta $d800,x
	lda colors+$100,x
	sta $d900,x
	lda colors+$200,x
	sta $da00,x
	inx
	bne loop
	ldx #31
	loop2:
	lda colors+$300,x
	sta $db00,x
	dex
	bpl loop2
}

NextColumn:
	lda _tileOffset
	clc
	adc #$04
	sta _tileOffset
	cmp #$10
	bne exit

		lda #$0
		sta _tileOffset

		inc _tileIndex
		lda _tileIndex
		cmp _mapWidth
		bne exit
			lda _mapScrollLooped
			bne loop
			lda #0
			sta _mapScrollEnabled
			loop:
			lda #0
			sta _tileIndex
	exit:
	rts


