BasicUpstart2(start)

//----------------------------------------------------------

#import "Mem.asm"
#import "Math.asm"

.const SPR_Player = 0
.const SPR_Coin = 1

* = $1000 "Sprites.asm"
#import "Sprites.asm"

* = * "Sprite Animations"
_sprAnimEmpty: 			.import binary "data/Sprites_empty.anim"

_sprAnimDracRun: 		.import binary "data/Sprites_run.anim"
_sprAnimDracDie: 		.import binary "data/Sprites_death.anim"
_sprAnimDracVanish: 	.import binary "data/Sprites_vanish.anim"
_sprAnimDracAppear: 	.import binary "data/Sprites_appear.anim"
_sprAnimDracFalling: 	.import binary "data/Sprites_falling.anim"
_sprAnimDracToBat: 		.import binary "data/Sprites_tobat.anim"
_sprAnimDracBat: 		.import binary "data/Sprites_bat.anim"
_sprAnimDracFromBat: 	.import binary "data/Sprites_frombat.anim"

_sprAnimCoinSpawn: 		.import binary "data/Sprites_coinspawn.anim"
_sprAnimCoinSpin: 		.import binary "data/Sprites_coinspin.anim"

*=$2000 "Map"
.var map = LoadBinary("data/test.map");
.var line = map.getSize()/5;
_map0: .fill $100, map.get(0*line + mod(i,line));
_map1: .fill $100, map.get(1*line + mod(i,line));
_map2: .fill $100, map.get(2*line + mod(i,line));
_map3: .fill $100, map.get(3*line + mod(i,line));
_map4: .fill $100, map.get(4*line + mod(i,line));

*=$2500 "Tile Ptrs"
_tilePtr:
.lohifill $80, _tiles+16*i

*=$2600 "Tiles"
_tiles:
.var tiles = LoadBinary("data/Tiles.tile");
.fill tiles.getSize(), tiles.get( (i&$fff0) + ((i>>2)&$03) + ((i&$03)<<2) );

*=$2a00 "Tile Colors"
_tileColors:
.var tile_colors = LoadBinary("data/Tiles.cmap");
.fill tile_colors.getSize(), tile_colors.get( (i&$fff0) + ((i>>2)&$03) + ((i&$03)<<2) );

*=$3000 "Color Buffer 1" virtual 
_color1:
.fill $400, $08

*=$3400 "Color Buffer 2" virtual 
_color2:
.fill $400, $08

*=$3800 "Background"
_background:
.import binary "data/Screens.tile"

*=$3c00 "Background Colors"
_backgroundColors:
.import binary "data/Screens.cmap"

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
.import binary "data/Characters.font"

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
.import binary "data/Sprites.spr"

*=$a000 "Font Tile Ptrs"
_fontTilePtr:
.lohifill $80, _fontTiles+4*i

*=$a100 "Font"
_fontTiles:
.import binary "data/Font.tile"


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

        		// Make $A000 - $BFFF visible, without removing the kernel ($e000-$ffff)
        lda #%00110110
        sta $01

		jsr DrawIntro

		SwapToBuffer1()

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

        SprManagerInit($00,$09,$c0,$ff,OnSprCollision)

        SprSetHandler(SPR_Player, PlySpawn)
        SprSetHandler(SPR_Coin, CoinSpawn)

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
		sta $d016 // no scroll here
		sta $d015 // no sprites here

		jsr SprUpdate

        SetBorderColor(0)

		NextRasterIRQ($fc, irq2)

irq2:
        SetBorderColor(2)

		lda $27 // Turn sprites on again ($27 holds active sprite mask from SprUpdate)
		sta $d015

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
	iny // Can't use adc since it will destroy the carry which we need to roll into the next char
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
	rts
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
	CopyScreen(_color1, $d800)
	rts

DrawMap1:
	ScrollX(4,FONT4_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 0, 7)
	rts

DrawMap2:
	ScrollX(2,FONT6_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 7, 7)
	rts

DrawMap3:
	ScrollX(0,FONT0_BITS)
	ShiftBuffers(_screen1, _screen2, _color1, _color2, 14, 6)
	FillEdge(_map0, 0, _screen2, _color2)
	FillEdge(_map1, 4, _screen2, _color2)
	FillEdge(_map2, 8, _screen2, _color2)
	FillEdge(_map3, 12, _screen2, _color2)
	FillEdge(_map4, 16, _screen2, _color2)
	SwapToBuffer2()
	rts

DrawMap4:
	ScrollX(6,FONT2_BITS)
	CopyScreen(_color2, $d800)
	rts

DrawMap5:
	ScrollX(4,FONT4_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 0, 7)
	rts

DrawMap6:
	ScrollX(2,FONT6_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 7, 7)
	rts

DrawMap7:
	ScrollX(0,FONT0_BITS)
	ShiftBuffers(_screen2, _screen1, _color2, _color1, 14, 6)
	FillEdge(_map0, 0, _screen1, _color1)
	FillEdge(_map1, 4, _screen1, _color1)
	FillEdge(_map2, 8, _screen1, _color1)
	FillEdge(_map3, 12, _screen1, _color1)
	FillEdge(_map4, 16, _screen1, _color1)
	SwapToBuffer1()
	rts



//------------------------------------------------------------
// ($fa)->: String
// $20->: Target Position X
// $21->: Target Position Y
// $fc->: Color

_textIntro:
.byte 6,16,2
.text "DRAC"
.byte 0
.byte 7,14,6
.text "BOANEO"
.byte 0
.byte $ff

DrawIntro:
{
	DrawScreen(_textIntro)
	rts
}

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
	ldx #32
	loop2:
	sta screen+$300,x
	dex
	bpl loop2
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
	ldx #32
	loop2:
	lda from+$300,x
	sta to+$300,x
	dex
	bpl loop2
}


//------------------------------------------------------------
// $20->: Target Position X
// $21->: Target Position Y
// $fc->: Color
// A->: Char
DrawChar:
{
	.break
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
	adc #(>_color1)
	sta $27 // ($26) is now the color buffer
	adc #(>_screen1)-(>_color1)
	sta $29 // ($28) is now the screen buffer

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
	ldx _tileIndex		// Get the next tile index
	lda map_row,x
	tax
	lda _tilePtr,x
	sta $fe           	// Store the index as the low byte for the tilemap
	sta $fc
	lda _tilePtr+$80,x
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

_screenPtr: .lohifill 25, 40*i
_drawers: .word DrawMap0-1, DrawMap1-1, DrawMap2-1, DrawMap3-1, DrawMap4-1, DrawMap5-1, DrawMap6-1, DrawMap7-1
_drawMapPass: .byte 0
_screenBits: .byte SCREEN1_BITS
_fontBits: .byte FONT0_BITS
_tileOffset: .byte 0
_tileIndex: .byte 0
_coins: .byte 0

#import "Player.asm"
#import "Coin.asm"

// When the sprite collision handler is called:
// $fb is current sprite index
// ($fc) points to current sprite properties
// $f2 is other sprite index
// ($22) points to other sprite properties
OnSprCollision:
{
		lda $fb
		cmp #SPR_Player
		bne exit

		lda $f2
		cmp #SPR_Coin
		bne exit

		SprSetHandler(SPR_Coin, CoinPick)
		inc _coins

	exit:
		rts

}

//----------------------------------------------------------
//        *=$1000 "Music"
//       .import binary "ode to 64.bin"



//----------------------------------------------------------
// A little macro
.macro SetBorderColor(color) {
        lda #color
        sta $d020
}