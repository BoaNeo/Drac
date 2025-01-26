_coinRnd: .byte 0
_coinPos: .lohifill 20, 38+40*i 
_coinY: .fill 20, VIS_TOP + i*8-18

CoinSpawn:
{
	ldx _coinRnd
	lda _coinPos,x
	sta pt
	lda _coinPos+20,x
	clc
	adc _sprScreenHi
	sta pt+1
	lda pt:$ffff
	cmp #$46
	bne nocoin
	// Compensate for current scroll offset to place coin exactly on top of spawn pt.
	lda $d016 
	and #$07
	lsr
	clc
	adc #VIS_RIGHT+4
	SprSTA(SPR_X)
	// Y-coord is trivially looked up from the character row
	lda _coinY,x
	SprSTA(SPR_Y)
	// Spawn the coin
	SprSetAnimation(_sprAnimCoinSpawn, CoinEOA_Spawn)
	SprSetHandler(SPR_Coin, CoinSpawning)
nocoin:
	inx
	cpx #20
	bne exit
	ldx #$00
exit: stx _coinRnd
	rts
}

CoinSpawning:
{
	SprSBC(SPR_X, 1)
	rts
}

CoinSpinning:
{
	SprSBC(SPR_X, 1)
	cmp #$f0
	bcc on_screen

	SprSetAnimation(_sprAnimEmpty, 0)
	SprSetHandler(SPR_Coin, CoinSpawn)
on_screen:
	rts
}

CoinPick:
{
	SprSetAnimation(_sprAnimEmpty, 0)
	SprSetHandler(SPR_Coin, CoinSpawn)
	rts
}

CoinEOA_Spawn:
{
	SprSetAnimation(_sprAnimCoinSpin, 0)
	SprSetHandler(SPR_Coin, CoinSpinning)
	rts
}

