_state: .word PLY_Spawn

PlayerControl:
{
		SprMoveDown(1)
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

		SprSetAnimation(_sprAnimDracRun, 0)
	//    SprSetFlags(SPRBIT_Enabled)

		PlySetState(PLY_Run)
		rts
}

PLY_Run:
{
		SprLDA(SPR_Bits)
		and #SPRBIT_Grounded
		bne gnd

		SprSetAnimation(_sprAnimDracFalling, 0)
		PlySetState(PLY_Falling)
		rts

	gnd:
		lda $dc00
		ror
		bcs no_up
		SprSetAnimation(_sprAnimDracVanish, PLY_EOA_ReappearUp)
		PlySetState(PLY_TeleportUp)
		jmp PLY_TeleportUp
	no_up:
		ror
		bcs no_down
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
		SprLDA(SPR_Bits)
		and #SPRBIT_Grounded
		beq falling

		SprSetAnimation(_sprAnimDracRun, 0)
		PlySetState(PLY_Run)
		rts

	falling:

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
		SprMoveUp(1)
		rts
}

PLY_TeleportDown:
{
		SprMoveDown(1)
		rts
}

PLY_Appear:
{
		SprMoveDown(1)
		rts
}


PLY_Dead:
{
		SprMoveLeft(2)
		rts
}

PLY_EOA_ReappearUp:
{
		SprMoveUp($50)
		SprSetAnimation(_sprAnimDracAppear, PLY_EOA_StartRun)
		PlySetState(PLY_Appear)
		rts
}

PLY_EOA_ReappearDown:
{
		SprMoveDown($40)
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

