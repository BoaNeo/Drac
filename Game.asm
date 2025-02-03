_coins: .byte 0


GameInit:
{
	lda #$00
        sta $d020
        lda #$09
        sta $d021
        lda #$0b
        sta $d022
        lda #$0c
        sta $d023

        SprManagerInit($00,$09,$c0,$ff,OnSprCollision)

        SprSetHandler(SPR_Player, PlySpawn)
        SprSetHandler(SPR_Coin, CoinSpawn)

	IRQ_SetNext($d4, GameIRQ1)

wait:	lda _shouldDrawMap
	beq wait
        SetBorderColor(2)
        jsr DrawMap
        lda #$0
	sta _shouldDrawMap
        SetBorderColor(0)
        jmp wait
}

_shouldDrawMap: .byte 0

//----------------------------------------------------------
GameIRQ1:
{
        lda #$00
        sta $d021

	lda #$00
	sta $d016 // no scroll here

	lda $d018
	and #$80
	ora _screenBits
	ora #FONT_BITS
	sta $d018

        SetBorderColor(3)
	jsr SprUpdate
        SetBorderColor(0)

	IRQ_SetNext($f9, GameIRQ2)
	rts
}

GameIRQ2:
{
        lda $d011
        and #%11110111
        sta $d011

        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop

        lda _scrollX
	sta $d016

	lda $d018
	and #$80
	ora _screenBits
	ora _fontBits
	sta $d018

        lda #$01
	sta _shouldDrawMap

	IRQ_SetNext($32, GameIRQ3)
	rts
}

GameIRQ3:
{
	nop // Make sure raster is off the right edge before changing the color
	nop
	nop
	nop
        lda #$09
        sta $d021

	lda $27 // Turn sprites on again ($27 holds active sprite mask from SprUpdate)
	sta $d015

        lda $d011
        ora #%00001000
        sta $d011

	IRQ_SetNext($d4, GameIRQ1)
	rts
}

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