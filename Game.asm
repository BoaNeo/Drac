_coins: .byte 0


GameInit:
	lda #$06
        sta $d020
        lda #$0e
        sta $d021
        lda #$0c
        sta $d022
        lda #$0b
        sta $d023

        SprManagerInit($00,$09,$c0,$ff,OnSprCollision)

        SprSetHandler(SPR_Player, PlySpawn)
        SprSetHandler(SPR_Coin, CoinSpawn)

	IRQ_SetNext($d4, GameIRQ1)

        jmp *


//----------------------------------------------------------
GameIRQ1:
        SetBorderColor(3)
	lda #$00
	sta $d016 // no scroll here

	jsr SprUpdate

        SetBorderColor(0)

	IRQ_SetNext($fc, GameIRQ2)
	rts

GameIRQ2:
        SetBorderColor(2)

        jsr DrawMap

        SetBorderColor(0)

	IRQ_SetNext($d4, GameIRQ1)
	rts


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