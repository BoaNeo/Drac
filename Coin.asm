_tokenPos: .lohifill 20, 38+40*i 
_tokenType: .byte 0
_coinY: .fill 20, VIS_TOP + i*8-7
_bloodY: .fill 20, VIS_TOP + i*8+2

TokenSpawn:
{
		ldx #$00
	loop:
		lda _tokenPos,x
		sta pt
		lda _tokenPos+20,x
		clc
		adc _sprScreenHi
		sta pt+1
		lda pt:$ffff
		ldy #0 // Y holds the type of coin
		cmp #$49
		beq spawn
		iny
		cmp #$79
		beq spawn
		inx
		cpx #20
		bne loop
		rts
	spawn:
		sty _tokenType
		// Compensate for current scroll offset to place coin exactly on top of spawn pt.
		lda $d016 
		and #$07
		lsr
		clc
		adc #VIS_RIGHT+4
		SprSTA(SPR_X)
		// Spawn the coin
		ldy _tokenType
		cpy #1
		beq token_blood
		// Y-coord is trivially looked up from the character row
		lda _coinY,x
		SprSTA(SPR_Y)
		SprSetAnimation(_sprAnimCoinSpawn, CoinEOA_Spawn)
		SprSetHandler(SPR_Token, TokenSpawning)
		rts
	token_blood:
		// Y-coord is trivially looked up from the character row
		lda _bloodY,x
		SprSTA(SPR_Y)
		SprSetAnimation(_sprAnimBloodSpawn, BloodEOA_Spawn)
		SprSetHandler(SPR_Token, TokenSpawning)
		rts
}

TokenSpawning:
{
	SprSBC(SPR_X, 1)
	rts
}

TokenSpinning:
{
	SprSBC(SPR_X, 1)
	cmp #$f0
	bcc on_screen

	SprSetAnimation(_sprAnimEmpty, 0)
	SprSetHandler(SPR_Token, TokenSpawn)
on_screen:
	rts
}


TokenPick:
{
	SprSetAnimation(_sprAnimEmpty, 0)
	SprSetHandler(SPR_Token, TokenSpawn)
	rts
}

CoinEOA_Spawn:
{
	SprSetAnimation(_sprAnimCoinSpin, 0)
	SprSetHandler(SPR_Token, TokenSpinning)
	rts
}

BloodEOA_Spawn:
{
	SprSetAnimation(_sprAnimBloodSpin, 0)
	SprSetHandler(SPR_Token, TokenSpinning)
	rts
}

