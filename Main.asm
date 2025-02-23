BasicUpstart2(Start)

//----------------------------------------------------------

#import "Colors.asm"
#import "Mem.asm"
#import "Math.asm"

* = $1000 "Sprites.asm"
#import "Sprites.asm"

* = * "Sprite Animations"
_sprAnimEmpty: 		.import binary "data/Sprites_empty.anim"

_sprAnimDracRun: 	.import binary "data/Sprites_run.anim"
_sprAnimDracDie: 	.import binary "data/Sprites_death.anim"
_sprAnimDracVanish: 	.import binary "data/Sprites_vanish.anim"
_sprAnimDracAppear: 	.import binary "data/Sprites_appear.anim"
_sprAnimDracFalling: 	.import binary "data/Sprites_falling.anim"
_sprAnimDracToBat: 	.import binary "data/Sprites_tobat.anim"
_sprAnimDracBat: 	.import binary "data/Sprites_bat.anim"
_sprAnimDracFromBat: 	.import binary "data/Sprites_frombat.anim"

_sprAnimCoinSpin: 	.import binary "data/Sprites_coinspin.anim"
_sprAnimBloodSpin: 	.import binary "data/Sprites_bloodspawn.anim"
_sprAnimDoorClosed: 	.import binary "data/Sprites_doorclosed.anim"
_sprAnimDoorOpen: 	.import binary "data/Sprites_dooropen.anim"
_sprAnimSwitchOff: 	.import binary "data/Sprites_switchoff.anim"
_sprAnimSwitchOn: 	.import binary "data/Sprites_switchon.anim"

*=$2000 "Map"
.var map = LoadBinary("data/Map01.map");
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
.var tiles = LoadBinary("data/Foreground.tile");
.fill tiles.getSize(), tiles.get( (i&$fff0) + ((i>>2)&$03) + ((i&$03)<<2) );

*=$2a00 "Tile Colors"
_tileColors:
.var tile_colors = LoadBinary("data/Foreground.cmap");
.fill tile_colors.getSize(), tile_colors.get( (i&$fff0) + ((i>>2)&$03) + ((i&$03)<<2) );

*=$3000 "Color Buffer 1" virtual 
_color1:
.fill $400, $08

*=$3400 "Color Buffer 2" virtual 
_color2:
.fill $400, $08

*=$3800 "Background"
_background:
.import binary "data/Backgrounds.tile"

*=$3c00 "Background Colors"
_backgroundColors:
.import binary "data/Backgrounds.cmap"

.const SCREEN1_BITS = %0000<<4
*=$4000 "Screen Buffer 1" virtual 
_screen1:
.fill $400, $80

.const SCREEN2_BITS = %0001<<4
*=$4400 "Screen Buffer 2" virtual
_screen2:
.fill $400, $80

.const FONT_BITS = %001<<1
*=$4800 "Font"
_font1:
.import binary "data/Font.font"

.const GFX0_BITS = %010<<1
*=$5000 "GameGfx Shift 0"
_gfx1:
.import binary "data/Game.font"

.const GFX2_BITS = %011<<1
*=$5800 "GameGfx Shift 2" virtual
_gfx2:

.const GFX4_BITS = %100<<1
*=$6000 "GameGfx Shift 4" virtual
_gfx3:

.const GFX6_BITS = %101<<1
*=$6800 "GameGfx Shift 6" virtual
_gfx4:

*=$7000 "Sprite Graphics"
_spriteGfx:
.import binary "data/Sprites.spr"

*=$a000 "Font Tile Ptrs"
_fontTilePtr:
.lohifill $80, _fontTiles+4*i

*=$a100 "Font"
_fontTiles:
.import binary "data/BigFont2.tile"

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

	MemCpy(_gfx1,_gfx2,$800)

	lda #>_gfx2
	jsr ShiftFont
	lda #>_gfx2
	jsr ShiftFont

	MemCpy(_gfx2,_gfx3,$800)

	lda #>_gfx3
	jsr ShiftFont
	lda #>_gfx3
	jsr ShiftFont

	MemCpy(_gfx3,_gfx4,$800)

	lda #>_gfx4
	jsr ShiftFont
	lda #>_gfx4
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
	sec

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

