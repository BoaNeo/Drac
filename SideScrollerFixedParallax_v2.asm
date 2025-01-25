BasicUpstart2(start)

//----------------------------------------------------------

#import "Mem.asm"
#import "Math.asm"

* = $1000 "Sprite Code"
#import "Sprites.asm"

*=$1e00 "Sprite Animations"
_spriteAnimations:
_sprAnimDracRun:
.import binary "data/Dracula_run.anim"
_sprAnimDracDie:
.import binary "data/Dracula_death.anim"
_sprAnimDracVanish:
.import binary "data/Dracula_vanish.anim"
_sprAnimDracAppear:
.import binary "data/Dracula_appear.anim"
_sprAnimDracFalling:
.import binary "data/Dracula_falling.anim"

*=$2000 "Map"
.var map = LoadBinary("data/test.map");
.var line = map.getSize()/5;
_map0: .fill $100, map.get(0*line + mod(i,line));
_map1: .fill $100, map.get(1*line + mod(i,line));
_map2: .fill $100, map.get(2*line + mod(i,line));
_map3: .fill $100, map.get(3*line + mod(i,line));
_map4: .fill $100, map.get(4*line + mod(i,line));

*=$2600 "Tiles"
_tiles:
.var tiles = LoadBinary("data/MyTileSet.tile");
.fill tiles.getSize(), tiles.get( (i&$fff0) + ((i>>2)&$03) + ((i&$03)<<2) );

*=$2800 "Tile Colors"
_tileColors:
.var tile_colors = LoadBinary("data/MyTileSet.cmap");
.fill tile_colors.getSize(), tile_colors.get( (i&$fff0) + ((i>>2)&$03) + ((i&$03)<<2) );

*=$3000 "Color Buffer 1" virtual 
_color1:
.fill $400, $08

*=$3400 "Color Buffer 2" virtual 
_color2:
.fill $400, $08

*=$3800 "Background"
_background:
.import binary "data/Screen.tile"

*=$3c00 "Background Colors"
_backgroundColors:
.import binary "data/Screen.cmap"

.const SCREEN1_BITS = %0000<<4
*=$4000 "Screen Buffer 1" virtual 
_screen1:
.fill $400, $80

.const SCREEN2_BITS = %0001<<4
*=$4400 "Screen Buffer 2" virtual
_screen2:
.fill $400, $80

.const FONT0_BITS = %010<<1
*=$5000 "Font Shift 0"
_font1:
.import binary "data/MyTest.font"

.const FONT2_BITS = %011<<1
*=$5800 "Font Shift 2" virtual
_font2:

.const FONT4_BITS = %100<<1
*=$6000 "Font Shift 4" virtual
_font3:

.const FONT6_BITS = %101<<1
*=$6800 "Font Shift 6" virtual
_font4:

*=$7000 "Sprite Graphics"
_spriteGfx:
.import binary "data/Dracula.spr"

//----------------------------------------------------------
//----------------------------------------------------------
//   Simple IRQ
//----------------------------------------------------------
//----------------------------------------------------------

        * = $8000 "Main Program"

start:  sei
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315
        lda #$7f  // Kill all timer interrupts (bit 8 value is copied to all other bits that are not zero)
        sta $dc0d // CIA #1
        sta $dd0d // CIA #2

        lda #$81  // Enable raster interrupt (What does setting bit 8 do?)
        sta $d01a
        lda #$1b  // Set raster line interrupt (8 lower bits in d012, high bit is Bit 8 of d011, rest are default)
        sta $d011
        lda #$d4
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

		SwapToBuffer1()

        lda $dc0d // Why are both these read into A?
        lda $dd0d  

  		lda #$06
        sta $d020
        lda #$0e
        sta $d021
        lda #$0c
        sta $d022
        lda #$0b
        sta $d023

        lda #$01 // Ack IRQ
        sta $d019 
        cli

        SprManagerInit($00,$09,$c0,$ff)

        SprSetHandler(0, PlayerControl)

        jmp *	// Jump to self

.macro NextRasterIRQ(raster, address)
{
        lda #($1b | ( (raster>>1)&$80 ) )  // Set raster line interrupt (8 lower bits in d012, high bit is Bit 8 of d011, rest are default)
        sta $d011
        lda #(raster&$ff)
        sta $d012
        lda #<address
        sta $0314
        lda #>address
        sta $0315
		lda #$01 // Acknowledge raster interrupt
		sta $d019
        jmp $ea81
}

//----------------------------------------------------------
irq1:
        SetBorderColor(3)
		lda #$00
		sta $d016

//		jsr PlayerControl
//		inc $d001 // Gravity for sprite 0

		jsr SprUpdate

        SetBorderColor(0)

		NextRasterIRQ($fc, irq2)

irq2:
        SetBorderColor(2)
		lda $d018
		and #$80
		ora _screenBits
		ora _fontBits
		sta $d018
        jsr DrawMap
        SetBorderColor(0)

		NextRasterIRQ($d4, irq1)


//----------------------------------------------------------

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
	CopyColor(_color1)
	rts

DrawMap1:
	ScrollX(4,FONT4_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 0, 8)
	rts

DrawMap2:
	ScrollX(2,FONT6_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 8, 8)
	rts

DrawMap3:
	ScrollX(0,FONT0_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 16, 4)
	FillEdge(_map0, 0, _screen2, _color2)
	FillEdge(_map1, 4, _screen2, _color2)
	FillEdge(_map2, 8, _screen2, _color2)
	FillEdge(_map3, 12, _screen2, _color2)
	FillEdge(_map4, 16, _screen2, _color2)
	SwapToBuffer2()
	rts

DrawMap4:
	ScrollX(6,FONT2_BITS)
	CopyColor(_color2)
	rts

DrawMap5:
	ScrollX(4,FONT4_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 0, 8)
	rts

DrawMap6:
	ScrollX(2,FONT6_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 8, 8)
	rts

DrawMap7:
	ScrollX(0,FONT0_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 16, 4)
	FillEdge(_map0, 0, _screen1, _color1)
	FillEdge(_map1, 4, _screen1, _color1)
	FillEdge(_map2, 8, _screen1, _color1)
	FillEdge(_map3, 12, _screen1, _color1)
	FillEdge(_map4, 16, _screen1, _color1)
	SwapToBuffer1()
	rts

.macro ScrollX(amount, font_bits)
{
	lda #%11010000 // Turn on multicolor mode and shrink screen to 38 columns
	ora #amount
	sta $d016
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
	clc
	lda #0
	sta $ff 			// Reset the tilemap hi byte
	ldx _tileIndex		// Get the next tile index
	lda map_row,x
	sta $fe           	// Store the index as the low byte for the tilemap
	rol $fe            	// Then multiply by 16
	rol $ff
	rol $fe
	rol $ff
	rol $fe
	rol $ff
	rol $fe
	rol $ff
	lda $fe
	sta $fc
	lda $ff
	tay
	adc #>_tiles 		// Add the highbyte of the tile map to the tile offset
	sta $ff 			// Now ($fe) points to the relevant tile
	tya
	adc #>_tileColors	// Add the highbyte of the tile map to the color tile offset
	sta $fd 			// Now ($fe) points to the relevant color tile

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

.macro CopyColor(buffer)
{
	ldx #$00
	loop:
	lda buffer,x
	sta $d800,x
	lda buffer+256,x
	sta $d900,x
	lda buffer+512,x
	sta $da00,x
	inx
	bne loop
	ldx #32
	loop2:
	lda buffer+768,x
	sta $db00,x
	dex
	bpl loop2
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
	SprSetScreenPt(_screen1,_screen2)

	lda #SCREEN1_BITS
	sta _screenBits
	jsr NextColumn
}

.macro SwapToBuffer2()
{
	SprSetScreenPt(_screen2,_screen1)

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

#import "Player.asm"

//----------------------------------------------------------
//        *=$1000 "Music"
//       .import binary "ode to 64.bin"



//----------------------------------------------------------
// A little macro
.macro SetBorderColor(color) {
        lda #color
        sta $d020
}