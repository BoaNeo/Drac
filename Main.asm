BasicUpstart2(Start)

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
//   Main Entry Point
//----------------------------------------------------------
//----------------------------------------------------------

        * = $8000 "Main Program"

#import "IRQ.asm"
#import "Screen.asm"
#import "Intro.asm"
#import "Game.asm"
#import "SideScrollerFixedParallax_v2.asm"

Start:
		jsr IRQ_Init
      
      	// Make $A000 - $BFFF visible, without removing the kernel ($e000-$ffff)
        lda #%00110110
        sta $01

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

gameloop:
        jsr IntroInit

        jsr GameInit

        //jsr GameOverInit

        jmp gameloop

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

