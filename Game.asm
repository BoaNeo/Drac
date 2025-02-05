_coins: .byte 0


GameInit:
{
	SetBorderColor(BLACK)
	SetScreenColor(BROWN)
	SetMultiColor1(DARK_GREY)
	SetMultiColor2(GREY)
	SetSprColor1(BLACK)
	SetSprColor2(RED)

        SprManagerInit($c0,$ff,OnSprCollision)

        SprSetHandler(SPR_Player, PlySpawn)
        SprSetHandler(SPR_Coin, CoinSpawn)

	IRQ_SetNext($d1, GameIRQ1)

wait:	lda _shouldDrawMap
	beq wait
//        SetBorderColor(RED)
        jsr DrawMap
        lda #$0
	sta _shouldDrawMap
//        SetBorderColor(BLACK)
        jmp wait
}

_shouldDrawMap: .byte 0

//----------------------------------------------------------
GameIRQ1:
{
	SetScreenColor(BLACK)

	lda #$00
	sta $d016 // no scroll here

	lda $d018
	and #$80
	ora _screenBits
	ora #FONT_BITS
	sta $d018

//        SetBorderColor(CYAN)
	jsr SprUpdate
//        SetBorderColor(BLACK)

	IRQ_SetNext($f9, GameIRQ2)
	rts
}

GameIRQ2:
{
        lda $d011
        and #%11110111
        sta $d011


	IRQ_SetNext($102, GameIRQ3)
	rts
}

GameIRQ3:
{
        nop
        nop
        nop
        nop
	SetScreenColor(RED)

        lda _scrollX
	sta $d016

	lda $d018
	and #$80
	ora _screenBits
	ora _fontBits
	sta $d018

        lda #$01
	sta _shouldDrawMap

	IRQ_SetNext($32, GameIRQ4)
	rts
}

GameIRQ4:
{
	nop // Make sure raster is off the right edge before changing the color
	nop
	nop
	nop
	SetScreenColor(BROWN)

	lda $27 // Turn sprites on again ($27 holds active sprite mask from SprUpdate)
	sta $d015

        lda $d011
        ora #%00001000
        sta $d011

	IRQ_SetNext($d1, GameIRQ1)
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
