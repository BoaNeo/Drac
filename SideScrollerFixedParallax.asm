#import "Mem.asm"
#import "Math.asm"

.function ParseTileFile(filename)
{
	.var parsed_data = List()
	.var file_data = LoadBinary(filename)
	.var x0=0
	.var y0=0
	.for(var t=0;t<60;t++)
	{
		.for(var x=0;x<4;x++)
		{
			.for(var y=0;y<4;y++)
			{
				.var hi_byte = file_data.get((x0+x)*4+(y0+y)*(40*4+1)+1)
				.var lo_byte = file_data.get((x0+x)*4+(y0+y)*(40*4+1)+2)
				.var parsed = (ParseHex(hi_byte)<<4) | ParseHex(lo_byte)
				.eval parsed_data.add(parsed)
			}
		}
		.eval x0+=4
		.if(x0==40)
		{
			.eval x0=0
			.eval y0+=4
		}
	}
	.return parsed_data
}

.function ParseScreenFile(filename)
{
	.var parsed_data = List()
	.var file_data = LoadBinary(filename)
	.for(var y=0;y<24;y++)
	{
		.for(var x=0;x<40;x++)
		{
			.var hi_byte = file_data.get(x*4+y*(40*4+1)+1)
			.var lo_byte = file_data.get(x*4+y*(40*4+1)+2)
			.var parsed = (ParseHex(hi_byte)<<4) | ParseHex(lo_byte)
			.eval parsed_data.add(parsed)
		}
	}
	.return parsed_data
}

.function ParseHex(c)
{
	.if(c>='A')
		.return c-'A' + 10
	else
		.return c-'0'
}


BasicUpstart2(start)

*=$3000 "Map"
.var map = LoadBinary("data/test.map");
.var line = map.getSize()/6;
_map0: .fill $100, map.get(mod(i,line));
_map1: .fill $100, map.get(line + mod(i,line));
_map2: .fill $100, map.get(2*line + mod(i,line));
_map3: .fill $100, map.get(3*line + mod(i,line));
_map4: .fill $100, map.get(4*line + mod(i,line));
_map5: .fill $100, map.get(5*line + mod(i,line));


*=$3600 "Tiles"
_tiles:
.var tiles = LoadBinary("data/MyTileSet.tile");
.fill tiles.getSize(), tiles.get( (i&$f0) + ((i>>2)&$03) + ((i&$03)<<2) );

*=$3c00 "Background"
_background:
{
	.var list = LoadBinary("data/Screen.tile")
	.fill list.getSize(), list.get(i) | $80
}
/*
.for(var y=0;y<25;y++)
{
	.for(var x=0;x<40;x++)
	{
		.var c = (x & $f) + (($10*y)&$70)
		.if( (c&$f)==15 || (c&$f)==0 )
		{
			.byte $ff
		}
		else
			.byte ($80|c)
	}
}
*/

.const SCREEN1_BITS = %0000<<4
*=$4000 "Screen Buffer 1"  
_screen1:
.fill $400, $80 | ((i&$7)+(($10*i/40)&$3f))

.const SCREEN2_BITS = %0001<<4
*=$4400 "Screen Buffer 2"  
_screen2:
.fill $400, $80 | ((i&$7)+(($10*i/40)&$3f))

.const FONT0_BITS = %001<<1
*=$4800 "Font Shift 0"
_font1:
.var font = LoadBinary("data/MyTest.font");
.fill $800, font.get(i)
//.var tile_font = LoadPicture("tile_font.png")
//.fill $800, tile_font.getMulticolorByte((i>>3)&$0f, (i&7) | (i>>7)<<3)
//.fill $800, tile_font.getMulticolorByte(i>>7,i&$7f)

.const FONT2_BITS = %010<<1
*=$5000 "Font Shift 2" virtual
_font2:

.const FONT4_BITS = %011<<1
*=$5800 "Font Shift 4" virtual
_font3:

.const FONT6_BITS = %100<<1
*=$6000 "Font Shift 6" virtual
_font4:

//----------------------------------------------------------
//----------------------------------------------------------
//   Simple IRQ
//----------------------------------------------------------
//----------------------------------------------------------

        * = $8000 "Main Program"
start:  lda #$00
        sta $d020
        lda #$09
        sta $d021
        sei
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315
        lda #$7f  // Kill all timer interrupts (bit 8 value is copied to all other bits that are not zero)
        sta $dc0d // CIA #1
        sta $dd0d // CIA #2

        lda #$81  // Enable raster interrupt (What does setting bit 8 do?)
        sta $d01a
        lda #$1b  // Set raster line interrupt = 128 (8 lower bits in d012, high bit is Bit 8 of d011, rest are default)
        sta $d011
        lda #$ff
        sta $d012

		lda $dd00
		and #%11111100
		ora #%00000010 // Choose VIC Bank #1 ($4000-$7fff)
		sta $dd00

		MemCpy(_font1,_font2,$800)

		lda #>_font2
		jsr ShiftFont
		lda #>_font2
		jsr ShiftFont

		MemCpy(_font2,_font3,$800)

		lda #>_font3
		jsr ShiftFont
		lda #>_font3
		jsr ShiftFont

		MemCpy(_font3,_font4,$800)

		lda #>_font4
		jsr ShiftFont
		lda #>_font4
		jsr ShiftFont
/*
		MemFill(_font1+$07f8, 8, 0)
		MemFill(_font2+$07f8, 8, 0)
		MemFill(_font3+$07f8, 8, 0)
		MemFill(_font4+$07f8, 8, 0)
*/
        lda $dc0d // Why are both these read into A?
        lda $dd0d  

        lda #$00
        sta $d022
        lda #$0f
        sta $d023

        lda #$01 // Ack IRQ
        sta $d019 
        cli
        jmp *	// Jump to self

//----------------------------------------------------------
irq1:	lda #$01 // Acknowledge raster interrupt
		sta $d019

        SetBorderColor(2)
		lda $d018
		and #$80
		ora _screenBits
		ora _fontBits
		sta $d018
        jsr DrawMap
        SetBorderColor(0)

        jmp $ea81



// A : Highbyte of font to shift
ShiftFont:
{
	clc
	adc #$04 // Skip to upper half of font (negative characters)
	sta $ff
	lda #$00
	sta $fe

	lda #$08 // 8 rows of characters
	sta $fb

	top_loop:
	ldx #$08 // 8 bytes per character

	outer_loop:
	ldy #$00
	clc

	inner_loop:
	lda ($fe),y
	ror
	sta ($fe),y
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	iny
	tya
	bpl inner_loop

	Add_8to16($fe,$ff,1)
	dex
	bne outer_loop

	Add_8to16($fe,$ff,15*8)
	dec $fb
	bne top_loop
}


//------------------------------------------------------------

DrawMap:
{
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
    rts
}

DrawMap0:
	ScrollX(6,FONT2_BITS)
	ShiftBuffers(_screen1, _screen2, 0, 6)
	FillEdge(_map0, 0, _screen2)
	rts

DrawMap1:
	ScrollX(4,FONT4_BITS)
	ShiftBuffers(_screen1, _screen2, 6, 6)
	FillEdge(_map1, 4, _screen2)
	FillEdge(_map2, 8, _screen2)
	rts

DrawMap2:
	ScrollX(2,FONT6_BITS)
	ShiftBuffers(_screen1, _screen2, 12, 6)
	FillEdge(_map3, 12, _screen2)
//	ShiftBuffers(_color1, _color2, 0)
	rts

DrawMap3:
	ScrollX(0,FONT0_BITS)
	ShiftBuffers(_screen1, _screen2, 18, 6)
	FillEdge(_map4, 16, _screen2)
	FillEdge(_map5, 20, _screen2)
	SwapToBuffer2()
//	ShiftBuffers(_color1, _color2, 12)
	rts

DrawMap4:
	ScrollX(6,FONT2_BITS)
	ShiftBuffers(_screen2, _screen1, 0, 6)
	FillEdge(_map0, 0, _screen1)
	rts

DrawMap5:
	ScrollX(4,FONT4_BITS)
	ShiftBuffers(_screen2, _screen1, 6, 6)
	FillEdge(_map1, 4, _screen1)
	FillEdge(_map2, 8, _screen1)
	rts

DrawMap6:
	ScrollX(2,FONT6_BITS)
	ShiftBuffers(_screen2, _screen1, 12, 6)
	FillEdge(_map3, 12, _screen1)
//	ShiftBuffers(_color2, _color1, 0)
	rts

DrawMap7:
	ScrollX(0,FONT0_BITS)
	ShiftBuffers(_screen2, _screen1, 18, 6)
	FillEdge(_map4, 16, _screen1)
	FillEdge(_map5, 20, _screen1)
	SwapToBuffer1()
//	ShiftBuffers(_color2, _color1, 12)
	rts

.macro ScrollX(amount, font_bits)
{
	lda #%11010000 // Turn on multicolor mode and shrink screen to 38 columns
	ora #amount
	sta $d016
	lda #font_bits
	sta _fontBits
}

.macro ShiftBuffers(src, dest, row0, row_count)
{
	ldx #38
	loop:
	.for(var row=row0;row<row0+row_count;row++)
	{
		lda src+row*40+1,x
		bpl store
		lda _background+row*40+1,x
		store:
		sta dest+row*40,x
	}
	dex
	bpl loop
}

.macro FillEdge(map_row, row0, screen)
{
	clc
	lda #0
	sta $ff 			// Reset the tilemap hi byte
	ldx _tileIndex		// Get the next tile index
	lda map_row,x
	sta $fe           	// Store the index as the low byte for the tilemap
	rol $fe            	// Then multiply by 16
	rol $ff
//	clc
	rol $fe
	rol $ff
//	clc
	rol $fe
	rol $ff
//	clc
	rol $fe
	rol $ff
	lda $ff 			
//	clc
	adc #>_tiles 		// Finally, add the highbyte of the tile map to the tile offset
	sta $ff 			// Now ($fe) points to the relevant tile

	ldy _tileOffset   	// Tiles are arranged row-first, so index by y and increase one for each row
	.for(var row=0;row<4;row++)
	{
		lda ($fe),y 	// Get the character from the tile
		bpl store 		// negative values are background, so copy from the background
		lda _background+39+(row0+row)*40
		store: 			// Store character at edge
		sta screen+39+(row0+row)*40
		iny
	}
}

.macro SetPointer(field, ptr)
{
	lda #<ptr
	sta field
	lda #>ptr
	sta field+1
}

.macro SwapToBuffer1()
{
	lda #SCREEN1_BITS
	sta _screenBits
	jsr NextColumn
}

.macro SwapToBuffer2()
{
	lda #SCREEN2_BITS
	sta _screenBits
	jsr NextColumn
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

	exit:
	rts

_drawers: .word DrawMap0-1, DrawMap1-1, DrawMap2-1, DrawMap3-1, DrawMap4-1, DrawMap5-1, DrawMap6-1, DrawMap7-1
_drawMapPass: .byte 0
_screenBits: .byte SCREEN1_BITS
_fontBits: .byte FONT0_BITS
_tileOffset: .byte 0
_tileIndex: .byte 0



//----------------------------------------------------------
//        *=$1000 "Music"
//       .import binary "ode to 64.bin"



//----------------------------------------------------------
// A little macro
.macro SetBorderColor(color) {
        lda #color
        sta $d020
}