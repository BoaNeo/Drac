_state: .word PLY_Spawn

PlayerControl:
{
		jmp (_state)
}

.macro PlySetState(addr)
{
	lda #<addr
	sta _state
	lda #>addr
	sta _state+1
}

PLY_Spawn:
{
	    lda #80
	    SprSTA(SPR_X)
	    lda #80
	    SprSTA(SPR_Y)

	    SprSetFlags(SPRBIT_Ghost)

		SprSetAnimation(_sprAnimDracRun, PLY_EOA_Spawn)
		PlySetState(PLY_Spawning)
		rts
}

PLY_Spawning:
{
		rts
}

PLY_Run:
{
		SprLDA(SPR_CharAt)
		and #$f0
		bne alive

		SprSetAnimation(_sprAnimDracDie, PLY_EOA_Death)
		PlySetState(PLY_Dead)
		rts

alive:	SprLDA(SPR_CharBelow)
		and #$f0 // First 16 characters are "ground"
		beq gnd

		SprSetAnimation(_sprAnimDracFalling, 0)
		PlySetState(PLY_Falling)
		rts

	gnd:
		lda $dc00
		ror
		bcs no_up
	    SprSetFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracVanish, PLY_EOA_ReappearUp)
		PlySetState(PLY_TeleportUp)
		jmp PLY_TeleportUp
	no_up:
		ror
		bcs no_down
	    SprSetFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracVanish, PLY_EOA_ReappearDown)
		PlySetState(PLY_TeleportDown)
		jmp PLY_TeleportDown
	no_down:
		ror
		bcs no_left
		SprMoveLeft(2)
		rts
	no_left:
		ror
		bcs no_right
		SprMoveRight(1)
	no_right:
		rts
}

PLY_Falling:
{
		SprLDA(SPR_CharAt)
		and #$f0
		bne alive

		SprSetAnimation(_sprAnimDracDie, PLY_EOA_Death)
		PlySetState(PLY_Dead)
		rts

alive:	SprLDA(SPR_CharBelow)
		and #$f0 // First 16 characters are "ground"
		bne falling

//		SprSnapY()
		SprLDA(SPR_Y)
		and #$f8
		clc
		adc #2+3 // Because we snap to an even byte and row zero is at 50, so we're already 2 pixels up, the sprite is 21, adding additional 3 pixels to reach an even byte
		SprSTA(SPR_Y)

		SprSetAnimation(_sprAnimDracRun, 0)
		PlySetState(PLY_Run)
		rts

	falling:
		SprMoveDown(1)

		lda $dc00
		ror
		ror
		ror
		bcs no_left
		SprMoveLeft(1)
	exit:
		rts
	no_left:
		ror
		bcs no_right
		SprMoveRight(1)
	no_right:
		rts
}

PLY_TeleportUp:
{
		rts
}

PLY_TeleportDown:
{
		rts
}

PLY_Appear:
{
		rts
}

PLY_Dead:
{
		SprMoveLeft(1)
		SprLDA(SPR_CharBelow)
		and #$f0 // First 16 characters are "ground"
		bne falling

		SprLDA(SPR_Y)
		and #$f8
		clc
		adc #2+3 // Because we snap to an even byte and row zero is at 50, so we're already 2 pixels up, the sprite is 21, adding additional 3 pixels to reach an even byte
		SprSTA(SPR_Y)
		rts

	falling:
		SprMoveDown(1)
		rts
}

PLY_EOA_Spawn:
{
	    SprClearFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracRun, 0)
		PlySetState(PLY_Run)
		rts
}

PLY_EOA_Death:
{
		SprSetAnimation(_sprAnimDracAppear, 0)
		PlySetState(PLY_Spawn)
		rts
}

PLY_EOA_ReappearUp:
{
		SprMoveUp($48)
		SprClearFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracAppear, PLY_EOA_StartRun)
		PlySetState(PLY_Appear)
		rts
}

PLY_EOA_ReappearDown:
{
		SprMoveDown($38)
		SprClearFlags(SPRBIT_Ghost)
		SprSetAnimation(_sprAnimDracAppear, PLY_EOA_StartRun)
		PlySetState(PLY_Appear)
		rts
}

PLY_EOA_StartRun:
{
		SprSetAnimation(_sprAnimDracRun, 0)
		PlySetState(PLY_Run)
		rts
}

